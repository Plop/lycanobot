# speech.pl
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
#########################
# Speech functions
# (usual sentences)

our (%CFG, %messages, %special_jobs, %players, %chanusers, %cmdlist,
     %send_queue);

sub convert_escape_sequences {
    my $text = shift;
    $text =~ s/\\B/\002/g;
    $text =~ s/\\U/\037/g;
    $text =~ s/\\I/\026/g;
    $text =~ s/\\C/\003/g;
    $text =~ s/\\c/$CFG{'cmd_prefix'}/g;
    return $text;
}

# Choose a random string in an array of strings
# Arg 1 is a ref to the array
sub choose_rand_msg {
    my $array = shift;
    my $rand;

    $rand = int rand(@$array);
    return (@$array[$rand]);
}

# printf-format a message and return the formatted string
# Arg 1 : the text or a pointer to the text or a pointer to several text
# Arg 2 : eventual printf args
sub parse_msg {
    my ($text, @args) = @_;
    @args = () unless(@args);

    $text = $$text if(ref($text) eq "REF");

    # It's a %messages'string or array of strings
    if(ref($text) eq "ARRAY") {
	$text = choose_rand_msg($text);
    } elsif(ref($text) eq 'SCALAR') {
	$text = $$text;
    }

    $text = convert_escape_sequences($text);

    # Printf formatting
    if($text =~ /%[^%]/) {
	# Check for missing of arguments
	# " ".$text." " is a workaround to prevent the %'s not to be counted
	# by split() if they are at the beginning or the end of $text
	my $min_args = @_ = split(/%[^%]/, " ".$text." ");
	$min_args--;
	if(@args < $min_args) {
	    print "# warning : missing printf parameter(s) in message "
	        ."(exepted ".$min_args.", found ".@args.") :\n";
	    print "`".$text."'\n";
        }
	    
	$text = sprintf($text, @args);
    }

    # Charset conversion
    $text = charset_conv($text);
    return ($text);
}

# Converts an UTF-8 string into the charset given in the config file.
# If none was given that do nothing.
# Takes one arg, the string to convert.
# Returns the converted (or not) string.
sub charset_conv {
    my $text = shift;

    if($CFG{'charset'} ne 'utf8' || $CFG{'charset'} ne 'utf-8-strict') {
	# Not the native encoding, so convert

	# At the moment $text is in perl's internal form in UTF-8
	# Convert it to a byte sequence in $CFG{'charset'}, using
	# our translitteration module for non-convertible chars.
	$text = do_encode($CFG{'charset'}, $text, \&do_translit);
	# Now $text is a byte sequence, convert it to perl's internal format
	$text = do_decode($CFG{'charset'}, $text);
    }
    return $text;
}

# Return a sub that call say() using the given prio
sub sub_say {
    my (@args) = @_;

    if(ref($args[0]) eq 'HASH') {
	my $dargs = $args[0];
	return sub {
	    my ($sargs) = @_;
	    if(ref($sargs) eq 'HASH') { # Some options given
		$$dargs{$_} = $$sargs{$_} foreach(keys(%$sargs));
		shift;
	    }
	    say($dargs, @_);
	};
    } else { # backward compatibility
	return sub { say(@args, @_) };
    }
}

# Say function, for short
# The text to say can be a ref to a %messages'string
# or a simple string.
# Returns a list of the hashref messages placed in the send queue.
# When several messages are sent in a single say() call, this means:
# my $msg   = say(...); # $msg is the number of messages placed on the sendq
# my ($msg) = say(...); # $msg is the first one
# my @msg   = say(...); # you get all of them
sub say {
    my ($args, $text, @rest) = @_;
    if(ref($args) ne 'HASH') { # backward compatibility
	# my ($prio, $type, $to, $text, @args) = @_;
	$args = { 'prio' => $args, 'type' => $text, 'to' => shift(@rest) };
	$text = shift(@rest);
    }

    my %defaults =
	( 'prio' => 0, 'type' => '', 'to' => $CFG{'day_channel'},
	  'prefix' => '' );
    foreach(keys(%defaults)) { # apply defaults
	$$args{$_} = $defaults{$_} unless(exists($$args{$_}));
    }
    my ($prio, $type, $to) = ($$args{'prio'}, $$args{'type'}, $$args{'to'});

    my $t = 0;
    my @msgs;
    my $sent_mode = 'privmsg';
    my @hmsgs;

    $prio |= PRIO_NOERROR if($type ne 'error');

    # $text arg analysis and printf formatting
    $text = parse_msg($text, @rest);

    # Eventually divide into several messages
    @msgs = split("\n",$text);

    foreach my $i (0 .. $#msgs) {
	# put any player prefix on channel messages
	if(length($$args{'prefix'}) && $$args{'to'} =~ /^[#&]/) {
	    $msgs[$i] = lcfirst($msgs[$i]);
	    $msgs[$i] = $$args{'prefix'}.$CFG{'messages'}{'to_user_char'}.
		' '.$msgs[$i];
	}
	# put any wanted class message prefix
	if(exists($CFG{'messages'}{'message'}{$type})) {
	    $msgs[$i] = convert_escape_sequences
			    ($CFG{'messages'}{'message'}{$type}{'prefix'})
			.$msgs[$i];
	}
    }

    # select a prefered sent mode
    if(exists($CFG{'messages'}{'message'}{$type})) {
	$sent_mode = $CFG{'messages'}{'message'}{$type}{'send'}
    }

    # Send the message(s)
    foreach(@msgs) {
	$t = ( $CFG{'talk_speed'} == 0 ? 0 :
	       length($text)/$CFG{'talk_speed'});
	push(@hmsgs, push_on_sendqueue($prio,
			  {'type' => $sent_mode,
			   'to'   => $to,
			   'txt'  => $_,
			   'time' => $t
			   }));
    }
    return @hmsgs;
}

# Invites someone somewhere.
# Returns the hashref message placed in the send queue.
sub invite
{
    my ($prio, $ni, $chan) = @_;
    my $t = 0;
    $t = 1/$CFG{'mode_speed'} if($CFG{'mode_speed'} != 0);

    push_on_sendqueue($prio,
		      {'type' => 'invite',
		       'to'   => $ni,
		       'txt'  => $chan,
		       'time' => $t
		       });
}

# Returns the hashref message placed in the send queue.
# Sends a CTCP ping.
sub cping {
    push_on_sendqueue(PRIO_IRC_PROTO,
		      {'type' => 'cping',
		       'to'   => shift,
		       'txt'  => undef,
		       'time' => 1 # Good ?
		       });
}

# Announces someone's job. Also removes any deconnection timer pending.
# Unique are is the dead's nick
sub announce_death_job {
    my ($dead) = @_;
    
    say(P_GAMEADV, 'info', $CFG{'day_channel'},
	$messages{'deads'}{'announce_job'},
	$dead, $messages{'jobs_name'}{ $players{$dead}{'job'} });
    remove_deco_timer($dead);
}

# announce alives non-werewolves villagers (for werewolves)
# or alives villagers (including the special ones)
# $1 = where to say it (channel or nick)
# $2 = 'players' (means everybody), 'alives' or 'non-werewolves',
#      or nothing for everybody
sub announce_targs {
    my ($to, $who) = @_;
    my @targets;

    foreach(keys(%players)) {
	next if(($who eq 'alives' || $who eq 'non-werewolves') &&
		!$players{$_}{'alive'});
	next if($who eq 'non-werewolves' && $players{$_}{'job'} eq 'werewolf');
	push(@targets, $_);
    }
    if(@targets) {
	say(P_GAMEADV, 'info', $to,
	    $messages{'cmds'}{'helps'}{'show_choices'}, join(", ",@targets));
    }
}

# A simple /who command
# Returns the hashref message placed in the send queue.
sub who {
    my ($to) = @_;
    push_on_sendqueue(PRIO_IRC_PROTO,
		      {'type' => 'who',
		       'to'   => $to,
		       'txt'  => undef,
		       'time' => 1
		       });
}

# A simple /whois command
# Returns the hashref message placed in the send queue.
sub whois {
    my (@to) = @_;
    push_on_sendqueue(PRIO_IRC_PROTO,
		      {'type' => 'whois',
		       'to'   => '+server', # some virtual global destination...
		       'txt'  => [ map { make_user_pnick($_) } @to ],
		       'time' => 1
		       });
}

# Sends a raw line (for exotics commands)
# Arg 1: the line or a coderef which will generate it
# Arg 2(optionnal): the time to wait after it is sent, defaults to 1 second
# Returns the hashref message placed in the send queue.
sub raw_line {
    my ($line, $time, $prio) = @_;
    # Unusual lines are often IRC related
    push_on_sendqueue(defined($prio) ? $prio : PRIO_IRC_PROTO,
		      {'type' => 'raw',
		       'to'   => '',
		       'txt'  => $line,
		       'time' => defined($time) ? $time : 1
		       });
}
    
# Do a /oper
# Arg 1: nick
# Arg 2: password
# Returns the hashref message placed in the send queue.
sub oper {
    my ($ni, $pass) = @_;
    push_on_sendqueue(PRIO_IRC_PROTO,
		      {'type' => 'oper',
		       'to'   => $ni,
		       'txt'  => $pass,
		       'time' => 1
		       });
}

# Do a /kick.
# $reason is optional and defaults to an empty string. @args too, of course.
# Returns the hashref message placed in the send queue.
sub kick {
    my ($prio, $chan, $nick, $reason, @args) = @_;
    push_on_sendqueue($prio,
		      {'type' => 'kick',
		       'to'   => $nick,
		       'chan' => $chan,
		       'txt'  => defined($reason) ?
			   parse_msg($reason, @args) : '',
		       'time' => 1
		       });
}

# Do a /part.
# $reason is optional and defaults to an empty string. @args too, of course.
# Returns the hashref message placed in the send queue.
sub part {
    my ($prio, $chan, $reason, @args) = @_;
    push_on_sendqueue($prio,
		      {'type' => 'part',
		       'to' => $chan,
		       'txt'  => defined($reason) ?
			   parse_msg($reason, @args) : '',
		       'time' => 1
		       });
}

# Do a /join.
# Returns the hashref message placed in the send queue.
# We use the name irc_join to not to confuse with the perl's CORE::join()
sub irc_join {
    my ($prio, $chan, $time) = @_;
    push_on_sendqueue($prio,
		      {'type' => 'join',
		       'to' => $chan,
		       'time' => defined($time) ? $time : 1
		       });
}

# If at least one alive player on the given channel have tutorial mode
# enabled, return 1. Otherwise 0.
sub is_tuto_needed {
    my $to = shift;

    foreach(keys(%{ $chanusers{$to} })) {
	# avoid selecting non-playing users
	next if($_ eq $CFG{'nick'});
	next unless(exists($players{$_}));
	next if(!$players{$_}{'alive'}
		|| !get_infos($_)->{'tuto_mode'});
	
	return 1;
    }
    return 0;
}

# Ask for a player to type a given command(s)
# $1 = to who (player or channel)
# $2 = where to ask for it (player or channel)
# $2 = command name
# $3, $4, ...(optionnal) = other commands
# The intro is taken from the first command.
sub ask_for_cmd {
    my ($to, $where, $command, @cmds) = @_;
    my $needs_help = 0;
    my @message;
    our $round;
    my $intro;

    if(exists($cmdlist{$command}{'intro'})) {
	$intro = $cmdlist{$command}{'intro'};
    } elsif(exists($messages{'cmds'}{$command}{'intro'})) {
	$intro = $messages{'cmds'}{$command}{'intro'};
    }

    if(defined($intro)) {
	say(P_GAMEADV, 'query', $where, $intro);
    }

    if(!exists($players{$to}) && $to !~ /^\#/) {
	print '# warning : cannot ask for command '.$command
	    .' to an unknown player ('.$to.")\n";
	return;
    }

    # Find whether the player we are talking to OR someone in the channel,
    # needs help.
    if($to =~ /^\#/) { # channel
	$needs_help = is_tuto_needed($to);
    } else { # user
	$needs_help = get_infos($to)->{'tuto_mode'};
    }

    if($needs_help && $round <= 1) {
	@message = ( );
	# If there is more than one command, print all the commands even if
	# some don't takes args. Otherwise, skip printing it
	# if it don't takes args.
	my $params;
	foreach my $cmd ($command, @cmds) {
	    $params = get_cmd_params($cmd);
	    if(length($params) || @cmds) {
		push(@message, $CFG{'cmd_prefix'}.$cmd.$params);
	    }
	}
	if(@message) {
	    say(P_GAMEADV, 'info', $where,
		$messages{'cmds'}{'helps'}{'show_params'},
		join(', ',@message));
	    @message = ( );
	}

	# Here just print the commands with args
	my $example;
	foreach my $cmd ($command, @cmds) {
	    $example = get_cmd_example($cmd);
	    if(length($example)) {
		push(@message, $CFG{'cmd_prefix'}.$cmd.$example);
	    }
	}
	if(@message) {
	    say(P_GAMEADV, 'info', $where,
		$messages{'cmds'}{'helps'}{'show_example'},
		join(', ', @message));
	}
    }
}

# Returns the parameters syntax of a given command, or an empty string if there
# are no args.
sub get_cmd_params {
    my ($cmd) = @_;
    my $params;

    if(exists($cmdlist{$cmd}{'params'})) {
	$params = $cmdlist{$cmd}{'params'};
    } elsif(exists($messages{'cmds'}{$cmd}{'params'})) {
	$params = $messages{'cmds'}{$cmd}{'params'};
    }
    
    return '' unless(defined($params));

    # %messages string
    if(ref($params) eq "ARRAY") {
	return " ".choose_rand_msg($params);
    } else {
	return " ".$params;
    }
}

# Returns an example of parameters of a given command, or en empty string if
# there are no args.
sub get_cmd_example {
    my ($cmd) = @_;
    my $ex;

    if(exists($cmdlist{$cmd}{'example'})) {
	$ex = $cmdlist{$cmd}{'example'};
    } elsif(exists($messages{'cmds'}{$cmd}{'example'})) {
	$ex = $messages{'cmds'}{$cmd}{'example'};
    }

    return '' unless(defined($ex));

    # %messages string
    if(ref($ex) eq "ARRAY") {
	return " ".choose_rand_msg($ex);
    } else { # single string
	return " ".$ex;
    }
}

# Welcome someone
sub welcome {
    my $nick = shift;

    # Message priority nogame & noadmin
    say(0, 'info', $nick, $messages{'welcome'}{'welcome'},
	$CFG{'day_channel'}, $CFG{'cmd_prefix'}, $CFG{'cmd_prefix'});
    if(our $in_game) {
	say(0, 'info', $nick,
	    $messages{'welcome'}{'wait_game_end'});
    } else {
	say(0, 'info',$nick, $messages{'welcome'}{'wait_game_start'},
		    $CFG{'cmd_prefix'});
    }
}

# If a user not identified as a player take a player's nick, this sub
# warns him about it.
sub maybe_warn_unindent_player {
    my $nick = shift;
    if(exists($players{$nick}) && $players{$nick}{'deco_timer'}) {
	say(PRIO_GAME, 'info', $nick,
	    $messages{'outgame'}{'warn_unident_player'},
	    $nick, int timer_remaining($players{$nick}{'deco_timer'}));
    }
}

# Highlight the ones who want that
sub hl_them {
    our %users;
    my $when = shift;
    my @targets;

    # Look for the ones who want to be hl'ed, and not want to play yet
    foreach(keys(%users)) {
	if(get_infos($_)->{'hlme'} ne 'never' && !exists($players{$_})) {
	    push(@targets, $_);
	}
    }

    if(@targets == 1) {
	say(0, 'info', $CFG{'day_channel'},
	    $messages{'cmds'}{'hlme'}{'hl'}, @targets);
    } elsif(@targets > 1) {
	say(0, 'info', $CFG{'day_channel'},
	    $messages{'cmds'}{'hlme'}{'hls'}, join(', ',@targets));
    }
}

# Dynamic messages loading stuff
# Get the job name from the filename used by the caller's caller.
sub get_job_from_filename {
    my (undef, $filename) = caller(1);
    my ($job) = ($filename =~ /(.+)-.+.pl/);
    $job =~ s!^.+/!!; # Also delete path

    if(defined($job) && length($job)) { # looks good...
	return $job;
    } else {
	print "# error : couldn't get job name from file name \`$filename'\n";
	return undef;
    }
}

sub try_to_add_message {
    my ($hashref, $key, $msg, $what) = @_;
    my (undef, $file, $line) = caller(1);

    if(exists($$hashref{$key})) {
	print "# error : in $file:$line: couldn't add $what: it already exists\n";
    } else {
	$$hashref{$key} = $msg;
    }
}

sub add_job_name_message {
    my $job_name = shift;
    my $job = get_job_from_filename();
    return unless(defined($job));

    $messages{'jobs_name'} = {}
	unless(ref($messages{'jobs_name'}) eq 'HASH');
    try_to_add_message($messages{'jobs_name'}, $job, $job_name,
		       "job name message of \`$job'");
    return 1;
}

sub add_job_help_message {
    my $job_help = shift;
    my $job = get_job_from_filename();
    return unless(defined($job));

    $messages{'jobs_help'} = {}
	unless(ref($messages{'jobs_help'}) eq 'HASH');
    try_to_add_message($messages{'jobs_help'}, $job, $job_help,
		       "job help message of \`$job'");
    return 1;
}

sub add_phase_messages {
    my ($phase, %args) = @_;

    $messages{'phases'}{$phase} = {}
        unless(ref($messages{'phases'}{$phase}) eq 'HASH');

    while(my ($key, $msg) = each(%args)) {
	if($key eq 'name' || $key eq 'timeout' || $key eq 'timeout_announce') {
	    try_to_add_message($messages{'phases'}{$phase}, $key, $msg,
			       "phase $key message of \`$phase'");
	} else {
	    print "# warning : ignored unknown message key \`$_' in phase \`$phase'\n";
	}
    }
    return 1;
}

sub add_generic_messages {
    my (%args) = @_;
    my $job = get_job_from_filename();
    return unless(defined($job));

    $messages{'jobs'}{$job} = {} unless(ref($messages{'jobs'}{$job}) eq 'HASH');
    while(my ($key, $message) = each(%args)) {
	try_to_add_message($messages{'jobs'}{$job}, $key, $message,
			   "message with key \`$key'");
    }
    return 1;
}

sub add_cmd_messages {
    my $cmd = shift;
    my (%args) = @_;

    $messages{'cmds'}{$cmd} = {} unless(ref($messages{'cmds'}{$cmd}) eq 'HASH');
    while(my ($key, $message) = each(%args)) {
	try_to_add_message($messages{'cmds'}{$cmd}, $key, $message,
			   "message of command \`$cmd' with key \`$key'");
    }
    return 1;
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1
