# users.pl
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
##################################
# users managing stuff

our (%CFG, %users, @userlist, %chanusers);

# To update the @userlist hash entry of a player.
# If such entry do not exists, it creates a new one.
# arg 1 = the nick of the user we are dealing with
# Returns 1 if a new entry has been created in @userlist, 0 otherwise
sub update_user_infos {
    my ($nick) = @_;
    my $found = 0;
    my $private = undef;
    my $used_ident = undef;
    my @debug;

    if($nick eq $CFG{'nick'}) {
	return;
    }

    # Now we know all the $users{$nick}{'ident'} of that user,
    # check if he's a powerful Administrator or Moderator
    $users{$nick}{'admin'} = has_privilege('admins', $nick);
    $users{$nick}{'moder'} = $users{$nick}{'admin'} || has_privilege('moderators', $nick);

    # First, find out which ident we gonna use for this user
    foreach my $try (0..$#{$CFG{'ident'}}) {
	$used_ident = $try;
	foreach (split(/ +/, $CFG{'ident'}->[$try])) {
	    if($_ ne 'nick' && !defined($users{$nick}{'ident'}{$_})) {
		$used_ident = undef;
		last;
	    }
	}
	last if(defined($used_ident));
    }

    if(defined($used_ident)) { # It is identifiable
	# Look for this $nick in @userlist
	foreach my $priv (@userlist) {
	    $found = 1;
	    foreach my $ident (split(/ +/, $CFG{'ident'}->[$used_ident])) {
		# first check if that info is available in this $priv
		unless(defined($$priv{$ident})) {
		    $found = 0;
		    last;
		}
		if($ident eq 'nick') {
		    if($nick ne $$priv{$ident}) {
			$found = 0;
			last;
		    }
		} else {
		    unless(defined($users{$nick}{'ident'}{$ident})) {
			$found = 0;
			last;
		    }
		    if($users{$nick}{'ident'}{$ident} ne $$priv{$ident}) {
			$found = 0;
			last;
		    }
		}
	    }
	    if($found) {
		$users{$nick}{'private'} = \$priv;
		$private = $priv;
		last;
	    }
	}
    }

    if($users{$nick}{'admin'}) {
	push(@debug, "admin");
    } elsif($users{$nick}{'moder'}) {
	push(@debug, "moderator");
    }

    unless($found) {
	my $str = "new (";
	$private = build_default_private();
	push(@userlist, $private);
	$users{$nick}{'private'} = \$userlist[$#userlist];
	if(defined($used_ident)) {
	    $str .= "identified using ".$CFG{'ident'}->[$used_ident];
	} else {
	    $str .= "unidentifiable";
	}
	$str .= ")";
	push(@debug, $str);
    }

    print "-> User $nick is ".join(', ',@debug)."\n" if(@debug);

    # Try to recover players disconnections while in game
    if(exists($$private{'lycainfo'}{'game_nick'})) {
	ressurect_ply($nick, $$private{'lycainfo'}{'game_nick'});
	delete $$private{'lycainfo'}{'game_nick'};
    }

    # Update his ident if possible
    if(defined($used_ident)) {
	foreach(split(/ +/, $CFG{'ident'}->[$used_ident])) {
	    if($_ eq 'nick') {
		$$private{$_} = $nick;
	    } else {
		$$private{$_} = $users{$nick}{'ident'}{$_};
	    }
	}
	write_user_infos() if(!$found); # New user, remember him !
    }

    # Warn if using a disconnected player nick while not beeing identified
    # as this player.
    maybe_warn_unindent_player($nick);

    return !$found;
}

# Creates a new empty personnal entry (without ident infos)
# with default values and return a ref to that hash.
sub build_default_private {
    my %infos =
     ('lycainfo' => {
	 'tuto_mode' => 1,
	 'hlme'      => 'never'
	 }
      );
    return \%infos;
}

# Adds or updates the user properties in %users and update the link to its
# private settings, calling update_user_infos().
# Also welcomes the user if needed.
# $nick is mandatory, but some other args can be avoided if they are not known.
sub update_user {
    my ($nick,$user,$host,$realname,$serv,$away,$regnick) = @_;
    my $domain;
    my %old_infos;

    if(defined($users{$nick}) && defined($users{$nick}{'ident'})) {
	while( my ($k,$v) = each(%{ $users{$nick}{'ident'} }) ) {
	    $old_infos{$k} = $v;
	}
    }
    
    if($nick eq $CFG{'nick'}) {
	return;
    }
    
    # Update these user informations
    $users{$nick}{'ident'}{'user'} = $user         if(defined($user));
    $users{$nick}{'ident'}{'server'} = $serv       if(defined($serv));
    $users{$nick}{'ident'}{'realname'} = $realname if(defined($realname));
    $users{$nick}{'ident'}{'regnick'} = $regnick   if(defined($regnick));

    # Ensure there are not XML invald chars in our data.
    # XML::Simple translate chars above \x7F in entities, but not below \x1F.
    # If we translate chars below \x1F into $#\d+; entites, XML::Simple convert
    # the & into &amp;, ending up with &amp;\d+;.
    # So we just delete these damn...
    foreach(keys(%{ $users{$nick}{'ident'} })) {
	next unless(defined($users{$nick}{'ident'}{$_}));
	if(ref(\$users{$nick}{'ident'}{$_}) eq 'SCALAR') {
		$users{$nick}{'ident'}{$_} =~ s/([\x00-\x1F])//g;
	}
    }

    $domain = undef;
    # The given $host is the full qualified  host name, but we have to
    # separate the hostname and the domain name (unless it's an IP).
    if(defined($host)) {
	if($host !~ /([0-9]+\.){3}[0-9]+/) { # TODO: IPv6
	    if($host =~ /([^\.]+)?(\..+)?/) {
		$host = $1;
		$domain = $2;
	    }
	}
	$users{$nick}{'ident'}{'host'} = $host;
	$users{$nick}{'ident'}{'domain'} = $domain;
    }

    $users{$nick}{'away'} = $away if(defined($away));
    $users{$nick}{'private'} = undef; # will be set in update_user_infos()

    # This is previously set (to 0, in on_join) only if want this user to be
    # welcomed. Otherwise, do not nag him if he were here before the bot.
    $users{$nick}{'welcomed'} = 1 unless(defined($users{$nick}{'welcomed'}));

    my @changes;
    if(%old_infos) {
	foreach(keys(%old_infos)) {
	    if(defined($old_infos{$_})
	       && $old_infos{$_} ne $users{$nick}{'ident'}{$_}) {
		push(@changes, $_." changed from `".$old_infos{$_}."' to `"
		     .$users{$nick}{$_}."'");
	    }
	}
	if(@changes) {
	    print "-> Player ".$nick.":\n-> ".join("\n->  ", @changes)."\n";
	}
    }
}

# Adds or updates some channel specific users informations in %chanusers.
# $flags is a string with some of the @, +, or % symbols.
sub update_chan {
    my ($nick, $chan, $flags) = @_;

    # Create the key so that we know he's here
    $chanusers{$chan}{$nick} = undef unless(exists($chanusers{$chan}{$nick}));
    return unless(defined($flags));

    if($flags =~ /[\@\%&~]/) {     # op (or half-op, super-op, owner)
	$chanusers{$chan}{$nick}{'op'} = 1;
	# No way to find that :/ assuming that ops are not voiced
	unless(defined($chanusers{$chan}{$nick}{'voiced'})) {
	    $chanusers{$chan}{$nick}{'voiced'} = 0;
	}
    }
    elsif($flags =~ /\+/) { # voice
	$chanusers{$chan}{$nick}{'voiced'} = 1;
	$chanusers{$chan}{$nick}{'op'} = 0;
    }
    else {  # normal user
	$chanusers{$chan}{$nick}{'op'} = 0;
	$chanusers{$chan}{$nick}{'voiced'} = 0;
    }
}

# Get the @userlist element of a user from his nick. It's just a shortcut.
# arg 1 : the nick of the one we are looking for
# arg 2(optional) : handle what to do if there is no @userlist hash found:
#                   1 if we want the sub to return undef if it doesn't find it,
#                   0 (default) if we want to get a ref to a dummy vanilla hash
# returns a hash ref to his 'lycainfo' entry, or undef if not found.
sub get_infos {
    my ($ni, $dummy) = @_;
    $dummy = 1 unless(defined($dummy));

    if($dummy) {
	my $default = build_default_private()->{'lycainfo'};
	return $default unless(exists($users{$ni}));
	return $default unless(exists($users{$ni}{'private'}));
    } else {
	return undef unless(exists($users{$ni}));
	return undef unless(exists($users{$ni}{'private'}));
    }

    return ${$users{$ni}{'private'}}->{'lycainfo'};
}

# Ask the server for some informations about a user or a channel.
# The information requested depends on what we needs.
sub ask_who_is {
    my $who = shift;

    # Do a /whois only if we need the regnick
    if(grep(/\W?regnick\W?/, @{ $CFG{'ident'} })
       || @{$CFG{'admins'}{'regnick'}}) {
	if($who =~ /^\#/) { # channel
	    my @nicks = keys(%{ $chanusers{$who} });
	    my $n = $CFG{'max_whois_params'};

	    # Don't whois ourselves
	    @nicks = grep {$_ ne $CFG{'nick'}} @nicks;
	    @nicks = grep {my $n = $_; !grep { $n eq $_ } @{$CFG{'ignore'}}}
			   @nicks; # and the ignoreds

	    while(@nicks) {
		$n = @nicks if($n > @nicks);
		whois(splice(@nicks, -$n));
	    }
	} else { # user
	    whois($who);
	}
	    
    } else { # Otherwise a simple /who is slighter
	who($who);
    }
}

# Writes out @userlist and the $CFG{'ident'}
# in an XML form in the users info file.
sub write_user_infos {
    our %files;

    my %data;
    my $ident;

    # Build the data structure using the XML style
    $data{'users'}{'user'} = [ @userlist ];
    foreach (0 .. $#{$CFG{'ident'}}) {
	$ident = $CFG{'ident'}->[$_];
	$data{'identification'}{'ident'}{$_}{'use'} = $ident;
    }

    return write_persistent_data(\%data, 'users', RootName => 'users_infos',
		  NumericEscape => 2, # &#\d+; escapes for irc colors
		  KeyAttr => {'ident' => 'try' });
}

# Reads the XML users infos file and load it in @userlist.
# Unique arg is the infos file name with its path.
sub read_user_infos {
    our %files;
    my $infos_file = $files{'homedir'}.'/'.$files{'users'}{'name'};
    my $ident;
    my $data;

    return 1 unless(-e $infos_file); # Not a fatal error
    $data = read_persistent_data('users',  KeyAttr => {'ident' => 'try' },
				 ForceArray => [ 'user', 'ident' ]);
    return 0 unless(defined($data));

    # Check if the ident used in this file is the one we use
    my @idents;
    foreach(sort { $a <=> $b } keys(%{$$data{'identification'}{'ident'}})) {
	push(@idents, $$data{'identification'}{'ident'}{$_}{'use'});
    }
    unless(ident_array_cmp(\@idents, $CFG{'ident'})) {
	print "# error: the identification informations in ".$infos_file
	     ." do not match the ones in the config file ".$files{'cfg'}
	     .".\n# Please manually fix that.\n";
	return 0;
    }

    @userlist = @{$$data{'users'}{'user'}}; # Loaded :)
    print "-> Loaded ".$infos_file."\n";
    return 1;
}

# Helps the sub above: it compares 2 idents arrays. E.g.:
# ( 'regnick', ' nick user  ') and ( ' regnick', 'user  nick' ) # equals
# ( 'nick' ) and ( 'regnick' ) # not equals
sub ident_array_cmp {
    my ($a,$b) = @_;
    return 0 if($#$a != $#$b);

    foreach(0 .. $#$a) {
	$$a[$_] =~ s/^ +//;
	$$b[$_] =~ s/^ +//;
	if($$a[$_] =~ / / || $$b[$_] =~ / /) {
	    if(!ident_array_cmp([ sort split(/ +/, $$a[$_]) ],
				[ sort split(/ +/, $$b[$_]) ])) {
		return 0;
	    }
	} else {
	    return 0 if($$a[$_] ne $$b[$_]);
	}
    }
    return 1;
}

# Builds a portable nick which designate a user. Used for irc messages.
sub make_user_pnick {
    my $ni = shift;
    return $ni unless(exists($users{$ni})); # may be a channel
    return \$users{$ni};
}

# Reads a portable nick which designate a user.
sub read_user_pnick {
    my $ref = shift;
    if(ref($ref) eq 'REF') {
	return $$ref->{'nick'};
    }
    return $ref; # may be a channel
}

# Builds a portable nick which designate a player. Used for game informations.
sub make_ply_pnick {
    our %players;
    my $ni = shift;
    return $ni unless(exists($players{$ni})); # may be a channel
    return \$players{$ni};
}

# Reads a portable nick which designate a player.
sub read_ply_pnick {
    return read_user_pnick(@_); # also get a 'nick' key
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1
