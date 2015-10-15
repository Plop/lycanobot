# config.pl
# Copyright (C) 2007,2008  Gilles Bedel
#
# This file is part of lycanobot.
#
# Lycanobot is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# Lycanobot is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with lycanobot; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

use strict;
use warnings;
################################
# config files related stuff

our %files;

# Loads an XML config file. Args directy passed to XMLin()
# (see perdoc XML::Simple).
# Returns the XMLin() returned hash, or undef if an error occured (in which case
# an error message is printed, and also kept in $@)
sub xml_load {
    my ($cfg_file, @opts) = @_;
    my $cfg = eval { XMLin($cfg_file, @opts) };

    if($@) {
	$@ =~ s/ at [^l].+$//;
	if($cfg_file !~ /\n/m && -e $cfg_file) {
	    print "# Error in $cfg_file: $@";
	} else {
	    print "# Error in raw xml: $@";
	}
	return undef;
    }
    return $cfg;
}

# Loads an XML config file with its defaults and test it against a validator.
# Arg 1: config file name or raw XML
# Arg 2: default config in raw XML, or a coderef that returns it
# Arg 3: config validator (optionnal)
# Arg 4 and more: XMLin() other args (see perldoc XML::Simple)
# Returns the config hash, or undef if an error occured (in which case
# an error message is printed, and also kept in $@).
sub load_config_file {
    my ($cfg_file, $default_cfg, $validator, @xml_cfg) = @_;
    my $dcfg;
    if(defined($default_cfg)) {
	$dcfg = xml_load(ref($default_cfg) eq 'CODE' ?
			 &$default_cfg : $default_cfg, @xml_cfg);
	return undef unless(defined($dcfg));
    }
    my $cfg = xml_load($cfg_file, @xml_cfg);
    return undef unless(defined($cfg));

    # Merge the default conf with the one red
    if(defined($dcfg)) {
	merge_hash(\$dcfg, $cfg);
    } else {
	$dcfg = $cfg;
    }

    if($validator && !validate_conf($validator, $dcfg)) {
	$@ =~ s/^/  /mg; # indent
	$@ = "# In config file $cfg_file:\n$@";
	print $@;
	return undef;
    }
    return $dcfg;
}

# The timer sub used to periodically sync data
sub write_sync_data {
    our %CFG;

    # Make the following functions temporary not to skip their job
    my $s = $CFG{'storing'}{'sync'};
    $CFG{'storing'}{'sync'} = -1;
    write_game_sets();
    write_user_infos();
    $CFG{'storing'}{'sync'} = $s;

    if($CFG{'storing'}{'sync'} > 0) {
	$files{'sync_timer'} = add_timer($CFG{'storing'}{'sync'}, \&write_sync_data);
    }
}

# Loads the lycanobot config file (first arg) and do some basic controls on the
# values red.
# If loading fails, leaves the %CFG unchanged and sets $@.
# Otherwise, sets $files{'cfg'} to the given arg.
# Returns 1 on success, 0 on failure (in which case
# an error message is printed, and also kept in $@).
sub load_lyca_config_file {
    our (%CFG, %special_jobs, %send_queue, %send_queue_time, %cmdlist);
    my $cfg_file = shift;
    my $dcfg =
    load_config_file($cfg_file, \&default_lyca_config, lyca_config_validator(),
		     KeyAttr => { 'message' => 'type',
				  'service' => 'name' },
		     ForceArray => [ 'message', 'mask',
				     'regnick', 'mode', 'service',
				     'command', 'ident', 'recover' ] );
    return 0 unless(defined($dcfg));

    # Create empty arrays if no <regnick> and <mask> supplied
    $$dcfg{'admins'}{'mask'} = [] unless(exists($$dcfg{'admins'}{'mask'}));
    $$dcfg{'admins'}{'regnick'} = [] unless(exists($$dcfg{'admins'}{'regnick'}));
    # Samde for the moderators
    $$dcfg{'moderators'}{'mask'} = [] unless(exists($$dcfg{'moderators'}{'mask'}));
    $$dcfg{'moderators'}{'regnick'} = [] unless(exists($$dcfg{'moderators'}{'regnick'}));

    # Create an array for the comma separated 'ignore' tag
    $$dcfg{'ignore'} = [ split(/,/, $$dcfg{'ignore'}) ];

    # In XML we group several variables into one tag for convenience.
    # Thus, we have our variables grouped into hashes. Here we ungroup them.
    foreach my $group ('conn', 'identity', 'talk', 'rate', 'modes',
		       'identification', 'sendq') {
	foreach(keys(%{$$dcfg{$group}})) {
	    $$dcfg{$_} = delete $$dcfg{$group}{$_};
	}
	delete $$dcfg{$group};
    }
    $$dcfg{'werewolves_proportion'} = delete $$dcfg{'werewolves'}{'proportion'};

    # Delete useless 'use' keys in ident and build an array
    # This changes from something like that:
    #     'ident' => [ { 'try' => '1', 'use' => 'user host realname' }
    #                  { 'try' => '2', 'use' => 'user host' } ]
    # To something like:
    # 'ident' => [ 'user host realname', 'user host' ]
    my @idents;
    foreach(sort { $$a{'try'} <=> $$b{'try'} }  @{ $$dcfg{'ident'} }) {
	push(@idents, $$_{'use'});
    }
    $$dcfg{'ident'} = [ @idents ];

    # Load the messages according to the chosen language
    if(!load_language($$dcfg{'language'})) {
	print $@;
	return 0;
    }

    # Protect the basic commands help messages.
    foreach(keys(%cmdlist)) {
	cmd_lock_help_keys($_);
    }

    # Load the charset conversion module if needed (not UTF-8 wanted)
    if(!load_charset(\$$dcfg{'charset'})) {
	print $@;
	return 0;
    }

    # Check for transliteration support, if not using unicode it's very usefull
    if($$dcfg{'charset'} !~ /^(utf-|utf8|ucs-)/i && do_translit(0x20) eq '?') {
	print "# warning : you are not using a unicode charset, so you should install the\n  Search::Tools::Transliterate module to have a good conversion to your charset.\n  Strange interrogations marks will appear in some messages.\n";
    }

    # Load the charset fallback conversion module if needed
    if(length($$dcfg{'charset_fallback'})) {
	if(!load_charset(\$$dcfg{'charset_fallback'})) {
	    print $@;
	    return 0;
	}
    }

    # Any admin or moderator ?
    unless(@{$dcfg->{'admins'}{'mask'}} || @{$dcfg->{'admins'}{'regnick'}}
	   || @{$dcfg->{'moderators'}{'mask'}}
	   || @{$dcfg->{'moderators'}{'regnick'}}) {
	$@ = "# warning : no admins or moderators specified, you will not\n"
	    ."            be able to do many things...\n";
	print $@;
    }

    # Update the %send_queue_time according to global_limit.
    if(exists($CFG{'global_limit'})) { # There is an old config hanging around
	# Convert global to per-dest
	if(is_true($CFG{'global_limit'})
	   && !is_true($$dcfg{'global_limit'})) {
	    foreach(keys(%send_queue)) {
		$send_queue_time{$_} = $send_queue_time{'global'};
	    }
	}
	# Convert per-dest to global
	elsif(!is_true($CFG{'global_limit'})
	      && is_true($$dcfg{'global_limit'})) {
	    my ($first_sq) = each(%send_queue);
	    %send_queue_time = (
		'global' => $send_queue_time{ $first_sq->[0]{'to'} },
		'last_dst' => undef
		);
	}
    }

    # (Re)load the data synchronization timers if they changed
    if(exists($CFG{'storing'}{'sync'})) { # a previous config exists
	if($CFG{'storing'}{'sync'} != $dcfg->{'storing'}{'sync'}) {
	    if(defined($files{'sync_timer'})) {
		remove_timer($files{'sync_timer'});
	    }
	    if($CFG{'storing'}{'sync'} > 0) {
		write_sync_data(); # (Re)loads a new timer
	    }
	}
    } else { # First config loading
	if($dcfg->{'storing'}{'sync'} > 0) {
	    $files{'sync_timer'} =
		add_timer($dcfg->{'storing'}{'sync'}, \&write_sync_data);
	}
    }

    %CFG = %$dcfg; # all right, overwrite old config
    $files{'cfg'} = $cfg_file;

    print "-> Loaded ".$cfg_file."\n";

    # Init send_queue_time stuff if needed
    if(is_true($CFG{'global_limit'})) {
	%send_queue_time = ( 'global' => -1,
			     'last_dst' => undef );
    }

    # Currently night_channel is only the basename, it needs to be expanded
    # if random night channel names are enabled.
    if(is_true($CFG{'use_random_night_channel'})) {
	generate_new_night_channel(1);
    }

    return 1;
}

# Regenerate the night channel name.
# Unique arg: 1 if the channel name doesn't already contain the random chars,
#             undef otherwise.
sub generate_new_night_channel {
    our %CFG;
    my @randchars = ( 'A'..'Z', 'a'..'z', 0..9 );
    my $len = 8;
    if(defined($_[0])) {
        $CFG{'night_channel'} .= '-';
	while($len--) {
	    $CFG{'night_channel'} .= $randchars[int((@randchars) * rand())];
	}
    } else {
        $CFG{'night_channel'} = substr($CFG{'night_channel'}, 0,-$len-1);
        generate_new_night_channel(1);
    }
}

# Copy $src hashes into $dst one if they are missing.
sub merge_hash {
    my ($dst, $src) = @_;

    if(ref($src) eq 'HASH') {
	foreach(keys(%$src)) {
	    merge_hash(\$$$dst{$_}, $$src{$_});
	}

    } elsif(ref($src) eq 'ARRAY') {
	$$dst = $src;
    } else {
	$$dst = $src;
    }
}

sub is_true {
    return 1 if($_[0] =~ /^(yes|true|1)$/i);
    return 0 if($_[0] =~ /^(no|false|0)$/i);
    return undef;
}

sub type2str {
    my $type = shift;
    my %conv =
      ( 'str' => 'a non-empty string', '' => 'a string (eventually empty)',
	'bool' => 'a boolean',
	'uint' => 'an unsigned int', 'int' => 'an integer',
	'ufloat' => 'an unsigned float', 'float' => 'a float',
	'hostmask' => 'a hostmask (nick!user@host)',
	'regexp' => 'a Perl regular expression'
      );
    if($type =~ /^\((.+)\)$/) {
	my $str = $1;
	$str =~ s/(\w+)/'$1'/g;
	return "one of the following strings: ".$str;
    } elsif(exists($conv{$type})) {
	return $conv{$type};
    } else {
	return '[dunno, you found a bug..]';
    }
}

# This is the core of the validating config system. It recursively checks $hash.
# Returns nothing if no errors are found, otherwise an ugly array that
# describes the error. Here is its format:
# ( "what were excepted", "what where found",
#   "in which key" [, "its parent key", "parents's parent",... ] )
#
# The "what were excepted" can also be _undef if an unexcepted key were found.
# It can also be _requiered if a requiered value (with a + prefix) were not
# found. In that case, "what were found" is undef. And if it's about the
# 'content' key, it means an tag which must not be empty is empty.
sub validate_hash {
    my ($valid, $hash) = @_;
    my @error;

    # Check for mandatory variables
    if(ref($valid) eq 'HASH') {
	# This sort() puts the 'content' key (which contains the content af a
	# tag such as "foo" in <a>foo</a>) at the end of the array.
	# Thus first it checks for required attributes, an then for the content.
	# This also prevents things like <modes><mode>+foo</mode></modes> to
	# produce a "empty tag found" error -- just too long to explain how/why.
	foreach(sort { return 1  if($a =~ /^\+?content$/);
		       return -1 if($b =~ /^\+?content$/); }
		keys(%$valid)) {
	    if(/^\+(.+)/) {
		if(ref($hash) eq 'HASH' && exists($$hash{$1})) {
		    $$valid{$1} = delete $$valid{$_};
		} else {
		    # Yes, it returns an error if it's not a hash
		    # or if it do not exists.
		    return ( ('_requiered', undef, $1) );
		}
	    }
	}
    }

    if(ref($valid) eq 'HASH' && ref($hash) eq 'HASH') {
	if(exists($$valid{'_type'}) || exists($$valid{'_content'})) {
	    foreach(keys(%$hash)) {
		if(exists($$valid{'_type'})) {
		    @error = ( validate_hash($$valid{'_type'}, $_) );
		    push(@error, $_), return @error if(@error);
		}
		if(exists($$valid{'_content'})) {
		    @error = ( validate_hash($$valid{'_content'}, $$hash{$_}) );
		    push(@error, $_), return @error if(@error);
		}
	    }

	} else {
	    foreach(keys(%$hash)) {
		@error = (  validate_hash($$valid{$_}, $$hash{$_})  );
		if(@error == 1) {
		    # You gave me $$hash{$_} while parsing $_
		    push(@error, ($$hash{$_}, $_));
		    return @error;
		}
		# A parent key
		push(@error, $_), return @error if(@error);
	    }
	}

    } elsif(ref($valid) eq 'ARRAY' && ref($hash) eq 'ARRAY') {
	foreach(@$hash) {
	    @error = validate_hash($$valid[0], $_);
	    # Arrays do not have keys
	    if(@error == 1) {
		push(@error, $_); # I was parsing $_ and ...
	    }
	    return @error if(@error);
	}

    } else { # SCALAR
	if(!defined($valid)) {
	    # An undefined value: $hash is not in the $valid hash
	    return '_undef'; # Not valid
	} elsif(!defined($hash) || ref($hash) ne ref($valid)) {
	    # Value not defined...
	    # Assume it's ok unless a '+' prefix were in the validator hash key.
	    return;
	} elsif($valid eq 'str') {
	    return type2str($valid) if($hash eq '');
	} elsif($valid eq 'bool') {
	    return type2str($valid) unless($hash =~ /^(0|1|yes|no|true|false)$/i);
	} elsif($valid eq 'uint') {
	    return type2str($valid) unless($hash =~ /^\d+$/);
	} elsif($valid eq 'int') {
	    return type2str($valid) unless($hash =~ /^[+\-]?\d+$/);
	} elsif($valid eq 'ufloat') {
	    return type2str($valid) unless($hash =~ /^\d+(\.\d+)?$/ # 3.14, ...
					   || $hash =~ /^\d+\/\d+$/); # 1/3, ..
	} elsif($valid eq 'float') {
	    return type2str($valid) unless($hash =~ /^[+\-]?\d+(\.\d+)?$/
					   || $hash =~ /^[+\-]\d+\/\d+$/);
	} elsif ($valid eq 'hostmask') {
	    return type2str($valid) unless($hash =~ /^[^!@]+![^!@]+@[^!@]+$/);
	} elsif($valid eq 'regexp') {
	    my $regexp = $hash;
	    $regexp =~ s/^!//;
	    eval "'' =~ $regexp";
	    return type2str($valid) if($@);
	} elsif($valid =~ /\((.+)\)/) {
	    my @valids = split(/,/, $1);
	    return type2str($valid) unless(grep(/^\Q$hash\E$/, @valids));
	}
    }
    return; # Yes return _nothing_, so it leaves @error empty if it's allright
}

# This validates a config data structure, using a validator hash.
# See control_lyca_config_vars() for an example. Here is how it works:
#
# This validator hash follows the config keys, but its values are the types the
# config values have to be in (see them a few lines above).
# When an array is in the validator, it has just one element. It means that an
# array must be found in the config, and each of its elements must be validated
# using the validator's cell.
#
# When a config variable name has to be controlled against a type, we use the
# _type key in the validator, which value is the variable name type.
# Her companion the _content key refers to the value of the variable (the one
# the name has been controlled by _type).
#
# Keys that are not found are just ignored, unless the key name in the
# validator hash is prefixed by a '+'. The config loading will fail if a +'ed
# key is not found.
#
# Arg 1: the validator hash
# Arg 2: the hash to check
# Returns 1 if allright, otherwise 0 and $@ explains why.
sub validate_conf {
    my ($validator, $check) = @_;

    my @err = ( validate_hash($validator, $check) );
    if(@err) {
	my $start = ( $err[0] =~ /^_/ ? 3 : 2);
	my $chain = join("' -> '", reverse @err[$start..$#err]);
	$@ .= "Error in '".$chain."':\n" if($chain);

	if($err[0] eq '_undef') {
	    $@ .= "Unknown tag/attribute/value: '".$err[2]."'.\n";
	} elsif($err[0] eq '_requiered') {
	    if($err[2] eq 'content') {
		$@ .= "That tag must be non-empty.\n";
	    } else {
		$@ .= "The mandatory tag/attribute/value '".$err[2]
		    . "' were not found.\n";
	    }
	} else {
	    $@ .= "Excepted ".$err[0]." but encountered '".$err[1]."'.\n";
	}
	return 0;
    }
    return 1;
}

# Simple sub only aimed to keep the lycanobot config validator out of real code.
sub lyca_config_validator {
    my %lyca_validator =
     ( 'conn' => {
	 'night_channel' => 'str', 'day_channel' => 'str', 'active' => 'bool',
	 'use_SSL' => 'bool', 'server' => 'str', 'port' => 'uint',
	 'timeout' => 'uint', 'use_random_night_channel' => 'bool'
       },
       'identity' => {
	   'nick' => 'str', 'irc_name' => 'str', 'user_name' => 'str',
	   'op_user' => 'str', 'op_passwd' => 'str'
       },
       'admins' => {
	   'mask' => [ 'hostmask' ],
	   'regnick' => [ 'str' ]
       },
       'moderators' => {
	   'mask' => [ 'hostmask' ],
	   'regnick' => [ 'str' ]
       },
       'ignore' => 'str',
       'init_special_jobs' => {
	   '_content' => 'bool' # dynamically added
       },
       'werewolves' => {
	   'proportion' => 'ufloat'
       },
       'identification' => {
	   'ident' => [ { '+try' => 'int',
			  '+use' => 'str' }
	   ]
       },
       'quit_recovery' => {
           'wait'    => 'uint',
           'recover' => [
               { '+on' => '(part,quit)',
                 'msg' => 'str',
                 'regexp' => 'regexp' }
               ]
       },
       'hacks' => {
	   'service' => {
	       'nick' => { '+nick' => 'str' },
	       'chan' => { '+nick' => 'str' }
	   },
	   'nick' => { '+password'   => 'str',  'say' => 'str' },
	   'chan' => { '+ask_invite' => 'bool', 'say' => 'str' },
	   'command' => [ '(sajoin)' ]
       },
       'modes' => { 'mode' => [
			{ '+on' => '(chanop,end_game,begin_game,connect)',
			  '+to' => '(day_channel,night_channel,ourself)',
			  '+content' => 'str' }
		    ] },
       'messages' => { 'message' => {
	   '_type'    => '(reply,info,query,error)',
	   '_content' => { 'send' => '(privmsg,notice)', 'prefix' => '' }
		       },
		       'to_user_char' => 'str'
       },
       'talk' => {
	   'cmd_prefix' => 'str', 'language' => 'str',
	   'charset' => 'str', 'charset_fallback' => '',
	   'decode_errors' => '(ignore,keep,warn)'
       },
       'rate' => {
	   'max_mode_params' => 'uint', 'max_whois_params' => 'uint',
	   'mode_speed'      => 'uint', 'talk_speed'       => 'uint',
	   'global_limit' => 'bool'
       },
       'sendq' => {
	   'max_bytes_sent' => 'int', 'max_bytes_time' => 'ufloat'
       },
       'storing' => { 'sync' => 'int' }
     );

    return \%lyca_validator;
}

# Loads the messages according to the chosen language
sub load_language {
    my ($conf_language) = @_;
    my $err = '';
    my $ret;

    if($conf_language ne DEFAULT_LANG) {
	my $default_loaded = 0;
    
	# First load the default lang, in case of the selected
	# language is incomplete.
	{
	    local $@;
	    $ret = do $files{'basedir'}."/messages/messages-".DEFAULT_LANG.".pl";
        }
        if($ret) {
	    $default_loaded = 1;
	} else {
	    $@ .= "# warning : cannot load the default base language ("
		 .DEFAULT_LANG.") : ".$!."\n";
	}
	  
	{
	    local $@;
	    $ret = do $files{'basedir'}."/messages/messages-".$conf_language.".pl";
        }
	unless($ret) {
	    $@ .= "# error : can't load the selected language ("
	         .$conf_language.") : ".$!."\n";
	    if($default_loaded) {
		$@ .= "  Falling back to the default language ("
		     .DEFAULT_LANG.")\n";
	    } else {
		$@ .= "  No languages available !\n";
		return 0;
	    }
	  }
      } else {
	  
	  {
	      local $@;
	      $ret = do $files{'basedir'}."/messages/messages-".DEFAULT_LANG.".pl";
	  }
	  unless($ret) {
	      $@ .= "# error : can't load the selected language ("
		   .DEFAULT_LANG.") : ".$!."\n";
	      return 0;
	  }
      }
    return 1;
}

# Loads the charset conversion module if needed (not UTF-8 wanted)
sub load_charset {
    my ($conf_charset) = @_;
    my $charset = $$conf_charset;

    my $ret;
    {   # Test if charset management is supported
	local $@;
	$ret = eval {require Encode};
    }
    unless($ret) {
	print "# warning : charset conversion require module Encode, "
	    ."which cannot be found. Using native UTF-8 charset.\n";
	$charset = 'utf8';
    }

    unless(defined(Encode::find_encoding($charset))) {
	print "# error: configuration charset '$charset' not found. Falling back to the \n"
	    ."  default and native UTF-8 charset. Supported charsets include :\n  "
	    .join(', ', Encode->encodings(':all'))
	    ."\n";
	$charset = 'utf8';
    }

    $$conf_charset = Encode::find_encoding($charset)->name;
    return 1;
}

sub create_default_config {
    my $cfg_file = shift;

    if(!open(CFG, "> ".$cfg_file)) {
	print "Cannot create a default ".$cfg_file." : ".$@."\n";
    } else {
	print "-> Creating a default config file (".$cfg_file."),\n"
	     ."   modify it as you want, then restart\n";
	print CFG default_lyca_config();
	close(CFG);
    }
}

# Reads the XML file $files{$file}{'name'} as a persistent data file.
# Returns the data structure on success, or undef on failure (in which case
# an error message is printed).
sub read_persistent_data {
    my ($file, @xml_opts) = @_;
    my $data;
    my $xml;
    my $filename = $files{'homedir'}.'/'.$files{$file}{'name'};
    
    # Read it
    if(open(XML, "<$filename")) {
	local $/;
	$xml = <XML>;
	close(XML);
    } else {
	print "# error: couldn't open $filename for reading: $!\n";
	return 0;
    }

    $data = eval { XMLin($xml, @xml_opts); };

    if($@) {
	$@ =~ s/ at [^l].+$//;
	print "# warning: cannot read $filename: ".$@;
	return undef;
    }
    $files{$file}{'md5'} = md5($xml);
    return $data;
}

# Write a given $data hashref to $files{$file}{'name'}, only if it differs
# from the last written data.
# Returns 1 on success, 0 on failure (in which case an error message is printed)
sub write_persistent_data {
    our %CFG;
    my ($data, $file, @xml_opts) = @_;
    my $xml;
    my $md5;
    my $filename = $files{'homedir'}.'/'.$files{$file}{'name'};

    # Skip if the writing is only performed by sync timers
    return 1 if($CFG{'storing'}{'sync'} >= 0);

    $xml = eval { XMLout($data, @xml_opts) };
    if($@) {
	$@ =~ s/ at [^l].+$//;
	print "# error: cannot parse data for writing to $filename: ".$@;
	return 0;
    }

    $md5 = md5($xml);
    # Do we want to write the same thing as before ?
    if(exists($files{$file})
       && defined($files{$file}{'md5'}) && defined($md5)) {
	return 1 if($md5 eq $files{$file}{'md5'});
    }

    # Write it
    if(open(XML, ">$filename")) {
	print XML $xml;
	close(XML);
	print "-> Wrote $filename\n";
    } else {
	print "# error: couldn't open $filename for writing: $!\n";
	return 0;
    }

    $files{$file}{'md5'} = $md5;
    return 1;
}

sub default_lyca_config {
########## Here comes the default config file ##########
    return <<EOT;
<?xml version='1.0'?>

<!-- Lycanobot\'s config file.
     Put all your bot\'s config here.
     True = true = Yes = yes = 1, and False = false = No = no = 0 -->

<lycaconf>
  <!-- These settings control how and where the bot has to connect.
     | Most of them are self-explicit.
     | "use_random_night_channel" make the night channel more hidden (thus
     | more secure) appending a minus and 8 random charachters to its name,
     | changing it for each game. For instance to "#village_night-p4FaAm13".
     | "active" set the bot awake. May be changed by the (de)activate commands.
     | "timeout" is the ping timeout limit that makes the bot to reconnect.
     | The bot had to be OP on both day_channel and night_channel. -->
  <conn server="irc.example.net" port="6667" use_SSL="no"
	day_channel="#village" night_channel="#village_night"
	use_random_night_channel="yes"
	active="yes" timeout="300" />

  <!-- Who is the bot? Put here his nick, irc name and user name.
       You may also put here the "op_user" and "op_passwd" attributes if you
       want the bot to ask to be an IRC Operator when it connects. -->
  <identity nick="lycanobot" irc_name="lycanobot"
            user_name="lycanobot vs 0.1.2"/>

  <admins>
    <!-- The admins\' identifiers.
       | They can do everything, including sensitive commands like reloadconf
       | and talkserv. Only for people you fully trust into.
       | There is no need to put the bot itself here, it\'s just some god :)
       | Here you can use the <mask> or <regnick> tag to specify who is admin.
       | <regnick> means a registered nick (done the nick service, see <hacks>
       | below). Just /whois someone to see who is it and put it here. Ex:
       |
       | <mask>*!some_ircname\@some_address</mask>
       | <mask>*!*@*.domain.org</mask>
       | <regnick>Jah</regnick>                                             -->
    <!-- Some people you fully trust into... -->
  </admins>

  <moderators>
    <!-- The moderators\' identifiers.
       | Exaclty the same as <admins> above (use <mask> or <regnick>), but this
       | time for the moderators. Such people are only able to moderate games
       | (stop game, change settings, and (de)activate the bot). Especially,
       | they cannot run sensitive commands like reloadconf and talkserv    -->
    <!-- Some people you normally trust into... -->
  </moderators>

  <!-- Ignored users.
     | Any users nicks which are in the day and/or night channel, but you want
     | to be ignored by the bot. He will not see they are in the channel with
     | him. Useful for ChanServ and others bots.
     | Separate multiple nicks with a comma, e.g. <ignore>foo,bar</ignore>  -->
  <ignore>ChanServ</ignore>

  <!-- The werewolves players proportion.
     | It\'s a number between 0 and 1. It can also be a fraction.
     | E.g. with <werewolves proportion="1/3" /> and 6 players
     | you\'ll get 2 werewolves and 4 villagers.
     | Note that 0.22 matches the official game advices. -->
  <werewolves proportion="0.22" />

  <!-- The identification mode.
     | This var configures the way the bot will identify real users from their
     | clones. Each user and his clones share the same personal information
     | and settings.
     | 
     | The bot is able to use the following informations to identify a user:
     | nick, user, host, domain, server, realname, regnick
     | Which refers to :
     | the nick, the /whois result user\@host.domain, the server name,
     | the real name, and the nick the user registered with.
     | When host is an IP, domain is unavailable.
     |
     | Some of these informations may not be available: domain and regnick.
     | That\'s why the bot is able to try some combinations before finding one
     | with all the informations requiered available. It will begin with try="1"
     | then try="2" and so on.
     |
     | If the bot is unable to identify a user because it can\'t collect
     | the informations you specify (in all the trys), the settings of that user
     | will remain only until he disconnects, and he will be considered as a new
     | user if he reconnects (the bot will welcome him etc.).
     |
     | Some examples:
     |  <ident try="1" use="user host domain" /> // This is the default : use
     |  <ident try="2" use="user host" />        // user\@domain.tld or user\@IP
     |
     |  <ident try="1" use="regnick"             // Use registration nick, or
     |  <ident try="2" use="user host domain"    // this, for unregistered users
     |
     |  <ident try="1" use="user domain" />      // Work around dynamic IPs,
     |  <ident try="2" use="user" />             // but it\'s unsecure
     |
     |  <ident try="1" use="nick" />             // On a trustworthy IRC network
   -->
  <identification>
    <ident try="1" use="user host domain" />
    <ident try="2" use="user host" />
  </identification>

  <!-- Quit recovery system
     | When a player quits during a game, lycanobot can continue the game as he
     | were here, until he comes backs and is recognized. Here you may set
     | when you want this to happens, using <recover> tags, depending on :
     |
     | - the type of the quit, attribute "on", can be "part" or "quit".
     | - the exit message, attribute "msg" (simple string) or "regexp" (a Perl
     |   regular expression). Put an '!' (exclamation mark) before the regexp to
     |   inverse its matching.
     |
     | In the wait="" attribute, you can also specify the maximum amount of time
     | (in seconds) the bot may wait before kicking the player out of the game,
     | if he havn't came back. Put zero if you don't want the bot to do that.
     |
     | Some examples:
     |  <recover on="quit" msg="EOF From client" />    // Simple EOF
     |  <recover on="quit" regexp="/^Ping timeout/" /> // Beginning with that
     |  <recover on="quit" regexp="!/^Quit: /" />      // Not starting with that
     |  <recover on="part" msg="Leaving" />            // Standard leaving  -->
  <quit_recovery wait="130">

  </quit_recovery>

  <!-- IRC Hacks
     | Here you tell the bot to use some specials IRC features.
     | Available hacks includes:
     | + Special commands, using the <command>name</command> tag.
     |   Lycanobot can use the SAJOIN command to force the werewolves to join
     |   their channel in the beginning of a game, instead of politely inviting
     |   them. Beware that you don\'t make sure they are ready if you force them.
     |   You may put <command>sajoin</command> for that.
     |   
     | + Services, using the <service> tag as following:
     |    <service name="the_foo_service" nick="FooServ">
     |    <the_foo_service feature="bar!" do_that="yes" ...>
     |
     |   Supported <service> "name" attribute values are "nick" and "chan".
     |   "nick" provides:
     |    - the "password" attribute (to make the bot identify itself)
     |    - the optionnal "say" attribute to tell the bot the message it
     |      must send in case it\'s not the regular "IDENTIFY <password>"
     |   For instance: <service name="nick" nick="NickServ" />
     |                 <nick password="bad" say="AUTH lycanobot bad"/>
     |   By the way, you can make the bot register with the "talkserv" command.
     |
     |   "chan" privides:
     |    - the boolean "ask_invite" attribute to tell the bot it must
     |      asks this service to invites it in the night channel
     |    - the optionnal "say" attribute, to tell the bot the message it
     |      must send in case it\'s not the regular "INVITE <#channel>"
     |   For instance: <service name="chan" nick="ChanServ" />
     |                 <chan ask_invite="yes" />                            -->
  <hacks>
    
  </hacks>

  <!-- Modes
     | /!\\  Warning: You should not change these settings unless you know
     [ ^|^           what you are doing! Defaults should be OK.
     | This specify which channel and user modes the bot have to set, and when.
     | "on" can be "connect", "chanop", "end_game" or "begin_game".
     | "to" can be "ourself" (results in a user mode, for the bot),
     |             "day_channel" or "night_channel".
     | +N channel mode was needed before, but it\'s no longer true.
     | The bot automatically sets the +i mode in the night channel, when
     | everybody in it has been kicked out. It also avoid setting a mode that
     | is already set.
     |
     | Some channel modes reminders:
     | n = no external messages
     | m = moderated chan, only voiced users may talk
     | s = secret channel (hidden from /whois etc.)
     | i = can be joined on invite only
     | The unofficial +B user mode (for bots) is quite common.
   -->
  <modes>
    <mode on="chanop"     to="day_channel">-m+n</mode>
    <mode on="end_game"   to="day_channel">-m</mode>
    <mode on="begin_game" to="day_channel">+m</mode>
    <!-- mode +i is automatically set on begin_game in the night channel -->
    <mode on="begin_game" to="night_channel">+mns</mode>
  </modes>

  <!-- Talk settings.
     | Handles how the bot talks and how users have to talk to it.
     | For the language, see which ones are available in the messages/
     | directory.
     |
     | "cmd_prefix" is the commands prefix character.
     | E.g. with cmd_prefix="!" you\'ll call the command "start" saying "!start"
     |
     | "charset" is the charset you want the bot to both talk in and listen in.
     | Default and native one is utf-8, others charsets need the Encode module.
     | Additionaly, iso-* users should install the Search::Tools::Transliterate
     | module to convert fancy utf-8 characters into iso equivalents, otherwise
     | you would get some '?' instead (e.g. '…' gets transliterated into '...').
     | Some common charsets : iso-8859-1, iso-8859-15, us-ascii, utf-8
     |
     | "charset_fallback", if non-empty, is the charset the bot will try to
     | decode input messages in, if the above "charset" failed. Usefull on
     | channels with users mixing utf8 and another charset.
     |
     | "decode_errors" sets what to do when it can\'t decode a message using
     | the above "charset" and "charset_fallback". Possible values include :
     | - "ignore" : messages with invalid characters will be silently ignored.
     | - "keep" : invalid characters will be kept in a hex form (\\xNN) and the
     |            the message will be parsed.
     | - "warn" : the bot will say a warning showing the problematic characters
     |            in a hex form and the message will be ignored.
     |
     | Note : control characters are always silently stripped after decoding.
     |        Also, non-multibytes charsets decoding cannot fail.
  -->
  <talk language="en" cmd_prefix="!"
       charset="utf8" charset_fallback="iso-8859-1"
       decode_errors="warn" />

  <!-- Messages settings.
     | Controls for each messages types how to say them:
     | - privmsg (classic irc message) or notice
     | - with an eventual prefix
     | By default all is sent in privmsg.
     |
     | Some special sequences can be used:
     |  \\B = start/stop blod
     |  \\U = start/stop underline
     |  \\I = start/stop italic
     |  \\Cxx = mIRC color number xx
     |
     | "to_user_char" is the completion char the bot will put after a nick
     | that prefixes a message said on a channel but for this specific nick.
     | E.g., with to_user_char=":" you\'ll get channel messages like :
     | "foobar: you cannot vote against your team."
  --> 
  <messages to_user_char=",">
    <message type="error" send="privmsg" prefix="" />
    <message type="info"  send="privmsg" prefix="" />
    <message type="query" send="privmsg" prefix="" />
    <message type="reply" send="privmsg" prefix="" />
  </messages>

  <!-- Rate control. These settings prevent the bot from flooding, and let it
     | readable.
     |
     | "talk_speed" is the talking speed in number of characters per seconds.
     | "max_mode_params" is the maximum number of players the bot can mode in
     | a single command. Check it in the irc server\'s config.
     | E.g. with "3" it will voice 3 players at the same time
     | using /mode +vvv player1 player2 player3
     |
     | "max_whois_params" is the same as "max_mode_params" but for /whois.
     | /whois are currently used by the bot only if you use the regnick flag
     | in the identification variables above. Otherwise /who is enougth.
     | E.g. with "4" it will whois 4 players at the same time
     | using /whois player1,player2,player3,player4
     |
     | "mode_speed" The number of modes the bot can do per seconds
     | Count 4 modes for doing something like +mnsi
     |
     | "global_limit". Is the previous limitations are global or for each user.
     | Set it if you want the bot to send a message to one user or channel
     | at a time. This would not makes the bot to heavily lag if he talks
     | to several users simultaneously (there is a round-robin between each
     | message destination), but must be used if the irc server have
     | per-user rate limitations. You should set it to "no" if you can.
  -->
  <rate talk_speed="20" mode_speed="1"
        max_mode_params="3" max_whois_params="4"
        global_limit="no" />

  <!-- Send queue control (has a superior priority than the rate contol).
     | These settings prevents flooding from a lower level. You may
     | exactly match the server receive queue restrictions, giving how much
     | bytes in can hold, and how long it takes to be entierly emptied.
     | For instance, using 1024 bytes and 6 seconds, the bot may send 1024
     | bytes instantly, but then would wait 6 seconds before sending anything
     | else. Also, if the bot continusly send some messages, its average rate
     | will never excess 1024/6 = 170 bytes per seconds.
     |
     | These settings can only work with the lycanobot patched version of
     | Net::IRC. To disable this feature, put a zero for one of the attributes.
  -->
  <sendq max_bytes_sent="512"
         max_bytes_time="0" /> <!-- Disabled by default. -->

  <!-- Persistent data is stored in some XML files, so that if lycanobot stops,
     | this stuff can be restored on restart.
     |
     | Note: Lycanobot can use a cache system not to write his data on disk
     | if it do not have changed. This feature is automatically enabled
     | if you have the Digest::MD5 module.
     |
     | "sync" You may want to save lycanobot\'s status on disk only after
     | a given time. Thus, the bigger this time is, the less your disk will
     | be used, but the more probably you can loose data if a crash happens.
     | Data is always saved on proper shutdown or reboot.
     | Use: -1 for full sync,
     |       0 for no sync (only on shutdown/reboot),
     |      or any time in seconds.
  -->
  <storing sync="3600" />
</lycaconf>

EOT
########### End of the default config file ###########
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1
