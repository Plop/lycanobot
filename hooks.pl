# hooks.pl
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
#############################
# hook's functions
# events that are called by Net::IRC
# (on_*)

our (%CFG, %messages, %chanmode, %players, %chanusers, %users, %cmdlist,
     $in_game);

# This sub fill the %users hash entry for each user.
# Each time time sub is called, one line (= one user) is received :
# nick(our), #chan, ircname, address, server, nick, flags,
# hops between your's and his server and real name.
sub on_whoreply
{
    my ($conn,$event) = @_;
    my ($our,$chan,$user,$host,$serv,$nick,$flags,$hops,$realname) = ($event->args);
    my $away = 0;

    return if(is_ignored($nick));

    if($flags =~ /^G/) {
	$away = 1;
    } elsif($flags =~ /^H/) {
	$away = 0;
    }

    if($chan ne '*') { # $chan eq '*' when using global /who
	update_chan($nick, $chan, $flags);
    }
    update_user($nick, $user, $host, $realname, $serv, $away, undef);
    if(update_user_infos($nick) && !$users{$nick}{'welcomed'}) {
	welcome($nick);
    }
}

# If someone changes his/her nick
sub on_nick
{
    my ($conn,$event) = @_;
    my ($newnick) = ($event->args);
    my $userhost = $event->userhost;
    my $ni = $event->nick;
    my $chan;

    if(exists($players{$ni}) && $players{$ni}{'connected'}) {
	if(exists($players{$newnick})) {
	    # Someone tries to get the nick of a disconnected player, kick him
	    slap_spoofer($ni, $newnick, $ni);
	} else {
	    $players{$newnick} = delete $players{$ni};
	    $players{$newnick}{'nick'} = $newnick;
	}
    }

    # Change its user nick
    if(is_ignored($ni)) {
	if(!is_ignored($newnick)) {
	    # Needed by the following ask_who_is
	    $users{$newnick}{'nick'} = $newnick;
	    ask_who_is($newnick); # No more ignored, new user
	}
    } else {
	unless(exists($users{$ni})) {
	    print '# warning : cannot change nick of an unknown user ('.
		$ni.") !\n";
	} else {
	    if(!is_ignored($newnick)) {
		$users{$newnick} = delete $users{$ni};
		$users{$newnick}{'nick'} = $newnick;
	    }
	    delete $users{$ni};
	}
    }

    # Change its nick in %chanusers (for IRC status)
    foreach $chan (keys(%chanusers)) {
	next unless(exists($chanusers{$chan}{$ni}));

	if(!is_ignored($newnick)) {
	    foreach(keys( %{$chanusers{$chan}{$ni}} )) {
		$chanusers{$chan}{$newnick}{$_} = $chanusers{$chan}{$ni}{$_};
	    }
	}
	delete $chanusers{$chan}{$ni};
    }

    print "* $ni is now known as $newnick\n";	
}

sub on_join
{
    my ($conn,$event) = @_;
    my ($ircn,$ni) = ($event->user, $event->nick);
    my ($chan) = ($event->to);
    print "* join : ".$ni." (".$event->userhost.") @ ".$chan."\n";

    if($ni eq $CFG{'nick'}) {
	# Making the channel as secret and invite only (+si) is very important
	# if we use random night channel names. So we set it here, ASAP,
	# even if we don't know what channel modes are set yet.
	if($chan eq $CFG{'night_channel'}
	   && is_true($CFG{'use_random_night_channel'})) {
	    mode(PRIO_IRC_PROTO|P_ADMIN, $CFG{'night_channel'}, '+si');
	}

	mode(PRIO_IRC_PROTO, $chan, ""); # Ask for chan mode
	# Asking for the user list is done in on_names
        return 1;
    }

    return if(is_ignored($ni));

    $chanusers{$chan}{$ni}{'op'} = 0;
    $chanusers{$chan}{$ni}{'halfop'} = 0;
    $chanusers{$chan}{$ni}{'voiced'} = 0;

    if($chan eq $CFG{'day_channel'}) {
	$users{$ni}{'welcomed'} = 0; # Let's welcome this new player
	$users{$ni}{'nick'} = $ni; # Needed by the following ask_who_is
	ask_who_is($ni); # get its IRC infos (will be done in on_whoreply)
    }

    # If we are waiting for the werewolves to join,
    # check if they are all in the night channel
    our %phs;
    if($phs{'current'} eq 'wait_werewolves') {
	do_next_step() if(have_werewolves_joined());
    }
}

# Checks if the werewolves are all in the night channel
sub have_werewolves_joined {
    foreach(keys(%players)) {
	if($players{$_}{'job'} eq 'werewolf' &&
	   !exists( $chanusers{ $CFG{'night_channel'} }{$_} )) {
	    return 0;
	}
    }
    return 1;
}

# /quit
sub on_quit {
    my ($conn,$event) = @_;
    my ($ni, $msg, $userhost) = ($event->nick, $event->args, $event->userhost);

    exclude_ply($ni, $msg, undef);
    print "* quit : ".$ni." [".$userhost."] (".$msg.")\n";
}


# /part
sub on_part
{
    my ($conn,$event) = @_;
    my ($ni, $msg, $userhost) = ($event->nick, $event->args, $event->userhost);
    my $chan = $event->to->[0];

    # Changing night channel ?
    if(is_true($CFG{'use_random_night_channel'})
       && $ni eq $CFG{'nick'} && $chan eq $CFG{'night_channel'}) {
	delete $chanusers{$chan};
	delete $chanmode{$chan};
	generate_new_night_channel(); # changes $CFG{'night_channel'}
	irc_join(P_GAMEADV, $CFG{'night_channel'}, 0);
    }

    # Kick him from $CFG{'night_channel'} if needed
    if($chan eq $CFG{'day_channel'}
       && exists($chanusers{$CFG{'night_channel'}}{$ni})) {
	kick(P_GAMEADMIN, $CFG{'night_channel'}, $ni,
	    $messages{'kick'}{'day_channel_left'}, $CFG{'day_channel'});
    }

    exclude_ply($ni, $msg, $chan);

    print "* part : ".$ni." [".$userhost."] (".$msg.") @ ".$chan."\n";
}

sub on_names
{
    my ($conn, $event) = @_;
    my @list = ($event->args);
    my $chan = $list[2];
    my @users = split(' ',$list[3]);
    my @nicks;

    # Joined !
    # See who's op and voiced
    foreach (@users) {
	my $ni = substr($_, 1); # delete the first char

	if(/^[\%\@\+&~]/) {
	    next if(is_ignored($ni));
	} else {
	    next if(is_ignored($_));
	}

	if(/^[\@&~]/) { # op (or super-op, owner)
	    $chanusers{$chan}{$ni}{'op'} = 1;
	    $chanusers{$chan}{$ni}{'halfop'} = 0;
	    $chanusers{$chan}{$ni}{'voiced'} = 0; # unknown but safer
	    push(@nicks, $ni);
       } elsif(/^\%/) { # halfop
            $chanusers{$chan}{$ni}{'op'} = 0;
           $chanusers{$chan}{$ni}{'halfop'} = 1;
           $chanusers{$chan}{$ni}{'voiced'} = 0;
           push(@nicks, $ni);
       } elsif(/^\+/) { # voice
           $chanusers{$chan}{$ni}{'op'} = 0;
           $chanusers{$chan}{$ni}{'halfop'} = 0;
           $chanusers{$chan}{$ni}{'voiced'} = 1;
            push(@nicks, $ni);
        } else {
            $chanusers{$chan}{$_}{'op'} = 0;
            $chanusers{$chan}{$_}{'halfop'} = 0;
            $chanusers{$chan}{$_}{'voiced'} = 0;
            push(@nicks, $_);
        }
}

    print "* ".@users." user(s) on ".$chan." : ".join(' ',@users)."\n";

    # Check if this random channel is actually already used by somebody 
    if(@users > 1 && $chan eq $CFG{'night_channel'}
       && is_true($CFG{'use_random_night_channel'})) {
       print "-> Whoops, this randomly choosen channel seems already used!\n"
            ."   Trying another one...\n";
       change_night_channel();
       return;
    }

    # Now we know who is on the channel, let's learn more about them
    if($chan eq $CFG{'day_channel'}) {
	# Needed by the following ask_who_is
	$users{$_}{'nick'} = $_ foreach(@nicks);
	ask_who_is($chan);
    }
}

sub on_mode {
    my ($conn, $event) = @_;
    my ($mode,@rest) = ($event->args);
    my ($chan) = ($event->to);
    my $launcher = $event->nick;
    my $moderest;

    # Avoid setting user modes here
    return if($chan eq $CFG{'nick'});

    # When $CFG{'night_channel'} is locked, purge it
    if($chan eq $CFG{'night_channel'} && $launcher eq $CFG{'nick'} && $mode eq '+i') {
	purge_night_chan();
    }

    # Divide possible multiple mode such as +vvv nick1 nick2 nick2
    $moderest = substr($mode, 1);
    $mode = substr($mode,0,2);
    do {
       	$moderest = substr($moderest,1);

	# Handle + and - modes such as +v-v nick1 nick2
	# in this case we end up with $mode = +- or $mode = -+
	if(substr($mode,1,2) eq '+' || substr($mode,1,2) eq '-') {
	    $mode = substr($mode,1);
	}
	else
	{
	    if(@rest > 0 && exists($chanusers{$chan}{$rest[0]})) {
		if($mode eq '+o') {
		    $chanusers{$chan}{$rest[0]}{'op'} = 1;
		} elsif($mode eq '-o') {
		    $chanusers{$chan}{$rest[0]}{'op'} = 0;
		    # TODO : call a /who or /whois to see if this user is +/-v
                } elsif($mode eq '+h') {
                   $chanusers{$chan}{$rest[0]}{'halfop'} = 1;
                } elsif($mode eq '-h') {
                   $chanusers{$chan}{$rest[0]}{'halfop'} = 0;
                } elsif($mode eq '+v') {
                   $chanusers{$chan}{$rest[0]}{'voiced'} = 1;
                } elsif($mode eq '-v') {
		    $chanusers{$chan}{$rest[0]}{'voiced'} = 0;
		}
	    }

	    # When we are op put the channel initial modes.
	    # If we don't know the channel modes yet, we can't see if the modes
	    # are already sets, so we will do that in on_chan_modeinfo().
	    if(exists($chanmode{$chan}) && $mode eq '+o'
	       && $rest[0] eq $CFG{'nick'} && (!$in_game)) {
		if($chan eq $CFG{'day_channel'}) {
		    mode_hook(PRIO_ADMIN, 'chanop', 'day_channel');
		} elsif($chan eq $CFG{'night_channel'}) {
		    mode_hook(PRIO_ADMIN, 'chanop', 'night_channel');
		}
	    }
	    
	    print "* mode : $mode ";
	    print $rest[0] if (@rest > 0);
	    print " @ ".$chan."\n";

	    # update any new channel modes
	    if(exists($chanmode{$chan})) {
		my ($s, $m) = (substr($mode,0,1), substr($mode,1,2));
		if($s eq '+' && $chanmode{$chan} !~ /\Q$m/) { # adding a mode
		    $chanmode{$chan} = $chanmode{$chan}.$m;
		} elsif($s eq '-' && $chanmode{$chan} =~ /\Q$m/) {
		    # deleting a mode
		    $chanmode{$chan} =~ s/\Q$m//;
		}
	    }
	    # handle possible other modes
	    shift(@rest);
	}
        $mode = substr($mode,0,1).substr($moderest,0,1);
    }
    until (length($moderest) == 0);

}

sub on_kick {
    my ($conn, $event) = @_;
    my ($chan, $reason) = ($event->args);
    my ($kicker) = ($event->nick);
    my ($kicked) = ($event->to);

    # damn, has I been kicked ?
    if($kicked eq $CFG{'nick'}) {
	delete $chanusers{$chan}; # Disconnected from $chan
	return;
    }

    exclude_ply($kicked, undef, $chan);
    print "* kick : ".$kicked." (by ".$kicker.") @ ".$chan.", reason : ".$reason."\n";
}

sub on_chan_modeinfo {
    my ($conn, $event) = @_;
    my ($from, $chan, $mode) = ($event->args); # (sender, chan, mode)

    $chanmode{$chan} = $mode;

    # Now we know what modes are set on the channel, we can make sure
    # wether +si is set or not (for random night channels), and set it
    # if needed. mode() will not do anything if this mode is already set.
    # In most of the cases, it should be already set (by on_join()).
    if($chan eq $CFG{'night_channel'}
       && is_true($CFG{'use_random_night_channel'})) {
	mode(PRIO_ADMIN, $CFG{'night_channel'}, '+si');
    }

    # Only useful if we get the channel mode after beeing opped
    if(!$in_game) {
	if(exists($chanusers{ $CFG{'day_channel'} }{ $CFG{'nick'} })
	   && $chanusers{ $CFG{'day_channel'} }{ $CFG{'nick'} }{'op'}) {
	    mode_hook(PRIO_ADMIN, 'chanop', 'day_channel');
	}
	if(exists($chanusers{ $CFG{'night_channel'} }{ $CFG{'nick'} })
	   && $chanusers{ $CFG{'night_channel'} }{ $CFG{'nick'} }{'op'}) {
	    mode_hook(PRIO_ADMIN, 'chanop', 'night_channel');
	}
    }

    print "* channel ".$chan." modes : ".$mode."\n";
}

# When we are connected...
sub on_connect
{
    my ($conn, $event) = @_;
    my ($nickserv, $ns_message);

    # First of all be an oper if needed
    if(exists($CFG{'op_user'}) && exists($CFG{'op_passwd'})) {
	oper($CFG{'op_user'}, $CFG{'op_passwd'});
    }

    print "* Connected.\n";
    $conn->{'connected'} = 1;

    mode_hook(PRIO_IRC_PROTO, 'connect');

    if(exists($CFG{'hacks'}{'service'}{'nick'})) {
	$nickserv = $CFG{'hacks'}{'service'}{'nick'}{'nick'};
	if(exists($CFG{'hacks'}{'nick'}{'say'})) {
	    $ns_message = $CFG{'hacks'}{'nick'}{'say'};
	} else {
	    $ns_message = "IDENTIFY ".$CFG{'hacks'}{'nick'}{'password'};
	}

	print "-> Identifying to ".$nickserv." ...\n";
	say(PRIO_IRC_PROTO, '', $nickserv, $ns_message);
    }

    irc_join(PRIO_IRC_PROTO, $CFG{'day_channel'});
    # We speed up the join with random night channels, so that initial
    # +si mode comes faster.
    irc_join(PRIO_IRC_PROTO, $CFG{'night_channel'},
	     is_true($CFG{'use_random_night_channel'}) ? 0 : undef);
}

# What to do when a msg is recieved
sub on_public
{
    our (%phs, %special_jobs);
    my ($conn, $event) = @_;
    my ($line) = ($event->args);
    my ($ni)   = ($event->nick);
    my ($to)   =  $event->to;
    my $is_valid; # used if it's a command
    my $talkto = $to;
    $talkto = $ni if($to eq $CFG{'nick'}); # if in pv, answer in pv    
    my $err = sub_say({'prio' => 0, 'type' => 'error', 'to' => $talkto,
		       'prefix' => $ni});
    my $decode_failed = 0;

    # Convert from an octet sequence assumed in $CFG{'charset'} to perl's
    # internal string.
    my $line_bak = $line; # decode() kills $line on failure (?)
    my $str = eval { do_decode($CFG{'charset'}, $line, Encode::FB_CROAK) };
    $line = $line_bak;
    $decode_failed = 1 unless(defined($str));
    # First charset decoding failed, try the fallback if any
    if($decode_failed && length($CFG{'charset_fallback'})) {
	$str = eval { do_decode($CFG{'charset_fallback'}, $line,
				Encode::FB_CROAK) };
	$line = $line_bak;
	$decode_failed = 0 if(defined($str));
    }
    if($decode_failed) {
	# Decoding failed or invalid chars found.
	$line = do_decode($CFG{'charset'}, $line, Encode::FB_PERLQQ);
	$decode_failed = 0 if($CFG{'decode_errors'} eq 'keep');
    } else {
	$line = $str;
    }
    $line =~ s/\x03(\d\d?(,\d\d?)?)?//g; # strip mIRC colors
    $line =~ s/\p{C}//g; # strip control/unallocated chars
    print "<$ni>  $line\n";

    return if(is_ignored($ni));

    # That souldn't happen, but check if we don't know this player
    unless(exists($users{$ni})) {
	print '# warning : an unknown user is talking to me ('.$ni.")\n";
	# Do not answer
	return;
    }

    # Disallow anything to nick spoofers
    return if(exists($players{$ni}) && exists($players{$ni}{'spoof'}));
	   
    # Don't read anymore if there were a decoding problem
    if($decode_failed) {
	if($CFG{'decode_errors'} eq 'warn') {
	    &$err($messages{'errors'}{'invalid_chars'}, $CFG{'charset'}, $line);
	}
	return;
    }

    # Not a command ?
    return unless($line =~ /^[\p{Z}]*\Q$CFG{'cmd_prefix'}\E(.+)/);

    ## Some tests about the command validity
    my ($cmd, @args) = split(/[\p{Z}]+/, $1); # 0x20 and utf8 specials spaces
    $cmd = lc($cmd);

    # Check if we are activated, or deactivated and it's an active admin
    # or moderator command
    unless(is_true($CFG{'active'})
	   || (!is_true($CFG{'active'}) && $cmd eq "activate"
	       && $users{$ni}{'moder'}) ) {
	return;
    }

    # Check if the command exists
    unless(exists($cmdlist{$cmd})) {
	&$err($messages{'errors'}{'unknown_cmd'}, $cmd, $CFG{'cmd_prefix'});
	return;
    }

    # Check if it needs moderator rights
    if($cmdlist{$cmd}{'need_moder'} && !$users{$ni}{'moder'}) {
	&$err($messages{'errors'}{'not_moder'}, $cmd);
	return;
    }

    # Check if it needs admin rights
    if($cmdlist{$cmd}{'need_admin'} && !$users{$ni}{'admin'}) {
	&$err($messages{'errors'}{'not_admin'}, $cmd);
	return;
    }

    # Any game command must be run by an active player
    if( ($cmdlist{$cmd}{'game_cmd'} || !exists($cmdlist{$cmd}{'game_cmd'}))
       && !(exists($players{$ni}) && $players{$ni}{'connected'}) ) {
	&$err($messages{'errors'}{'game_cmd'}, $cmd);
	return;
    }

    # Does the needed args has been provided ?
    if(exists($cmdlist{$cmd}{'min_args'})) {
	if(@args < $cmdlist{$cmd}{'min_args'}) {
	    &$err($messages{'errors'}{'not_enouth_args'},
		  $cmd, $cmdlist{$cmd}{'min_args'});
	    return;
	}
    }
		
    # Does the command has been launched from the right channel,
    # or the right one (if in private msg) ?
    foreach my $wh ('from', 'to') {
	if(exists($cmdlist{$cmd}{$wh})) {
	    my @valid_wh;
			
	    if(ref $cmdlist{$cmd}{$wh} eq "ARRAY") {
		@valid_wh = @{ $cmdlist{$cmd}{$wh} };
	    } else {
		@valid_wh = ( $cmdlist{$cmd}{$wh} );
	    }
			
	    $is_valid = 0;
	    foreach(@valid_wh) {
		if(ref($_) eq 'SCALAR') {
		    # We have a scalar ref, deref it to get the nick
		    next unless(defined($$_)); # Pointed value undefined yet
		    if ($wh eq 'from') {
			$is_valid = (lc($$_) eq lc($ni));
		    } else { # $wh eq 'to'
			$is_valid = (lc($$_) eq lc($to));
		    }
		} else {
		    # We have a simple scalar, it's a job name
		    if ($wh eq 'from' && exists($special_jobs{$_})
			&& defined($special_jobs{$_}{'nick'})) {
			$is_valid = ($ni eq read_ply_pnick($special_jobs{$_}{'nick'}));
		    } elsif($wh eq 'to') {
			if($_ eq 'us') {
			    $is_valid = (lc($to) eq lc($CFG{'nick'}));
			} elsif($_ eq 'day_channel') {
			    $is_valid = (lc($to) eq lc($CFG{'day_channel'}));
			} elsif($_ eq 'night_channel') {
			    $is_valid = (lc($to) eq lc($CFG{'night_channel'}));
			}
		    }
		}
		last if($is_valid);
	    }
	    
	    unless($is_valid) {
		if($wh eq 'from') {
		    &$err({'to' => $ni}, $messages{'errors'}{'not_auth'}, $cmd);
		    
		} elsif($to ne $CFG{'nick'}) { # $wh eq 'to'
		    &$err({'to' => $ni}, $messages{'errors'}{'need_privmsg'}, $cmd);
		    
		} else { # $wh eq 'to' && $to eq $CFG{'nick'}
		    &$err({'to' => $ni}, $messages{'errors'}{'no_privmsg'}, $cmd);
		}
		return;
	    }
	}
    }
	    
    # Are we in the right phase ?
    if(exists($cmdlist{$cmd}{'phase'})) {
	my @valid_phase;
	if(ref $cmdlist{$cmd}{'phase'} eq "ARRAY") {
	    @valid_phase = @{ $cmdlist{$cmd}{'phase'} };
	} else {
	    @valid_phase = ( $cmdlist{$cmd}{'phase'} );
	}
	
	$is_valid = 0;
	foreach(@valid_phase) {
	    if($phs{'current'} eq $_) {
		$is_valid = 1;
		last;
	    }
	}
	unless($is_valid) {
	    my @txt_phase;
	    foreach(@valid_phase) {
		if(exists($messages{'phases'}{$_}{'name'})) {
		    push(@txt_phase, $messages{'phases'}{$_}{'name'});
		}
	    }
	    if(@txt_phase) {
		&$err({'to' => $ni}, $messages{'errors'}{'wrong_time_wait_for'},
		    $cmd, join(", ",@txt_phase));
	    } else {
		&$err({'to' => $ni}, $messages{'errors'}{'wrong_time'}, $cmd);
	    }
	    if(grep({$_ eq 'no_game'} @valid_phase)) {
		&$err({'to' => $ni}, $messages{'errors'}{'in_game'});
	    }
	    return;
	}
    }
    
    # If not alive while the command needs it
    if($cmdlist{$cmd}{'need_alive'}
       && ( (exists($players{$ni}) && !$players{$ni}{'alive'})
	    || !exists($players{$ni}) )) {
	&$err($messages{'errors'}{'not_alive'}, $cmd);
	return;
    }
    
    # Does the command have a function associated ?
    unless(defined( &{ $cmdlist{$cmd}{'subaddr'} } )) {
	&$err($messages{'errors'}{'no_func_assoc'}, $cmd);
	return;
    }

    # Finnaly execute it !
    print "-> Calling ".$CFG{'cmd_prefix'}.$cmd."("
	.join(',',($ni,$talkto,@args))
	.")\n";
    &{ $cmdlist{$cmd}{'subaddr'} }($ni,$talkto,@args)
	or &$err($messages{'errors'}{'exe_failed'}, $cmd, $@);
}

# The bot should NEVER makes any auto response to a notice (rfc2812)
sub on_notice {
    my ($conn, $event) = @_;
    my ($line) = ($event->args);
    my ($ni)   = ($event->nick);
    my $to     = $event->to;
    
    if($to =~ /^\#/) { # channel
	print '-'.$ni.'/'.$to.'- '.$line."\n";
    } else { # from a user
	print '-'.$ni.'- '.$line."\n";
    }
}

# If the bot's nick is taken
sub on_nick_taken {
    my ($conn, $event) = @_;
    my $ni = $CFG{'nick'};

    # Pure badass hack follows
    $::run_mode = 2; # Restart!
    return;

    print "# warning : bot's nick (".$ni.") already taken, changing it "
	 ."to ".$ni."_\n";
    foreach(keys(%{ $users{$ni} })) {
	$users{$ni.'_'}{$_} = $users{$ni}{$_};
    }
    delete $users{$ni};
    $CFG{'nick'} = $ni.'_';

    $conn->nick($CFG{'nick'});
}

# The whois replies have all the bot's nick as first arg...
sub on_reg_info {
    my ($conn, $event) = @_;
    my ($our, $ni, $logged_as) = ($event->args);

    $users{$ni}{'ident'}{'regnick'} = $logged_as;
}

sub on_whoisuser {
    my ($conn, $event) = @_;
    my ($our, $ni, $user, $host, $wtf, $realname) = ($event->args);

    update_user($ni, $user, $host, $realname, undef, undef, undef);
}

sub on_whoischannels {
    my ($conn, $event) = @_;
    my ($our, $nick, $chans) = ($event->args);

    foreach my $chan (split(/ /,$chans)) {
	# $chans got something like @#foo or #bar or +#beer
	if($chan =~ /([^\#])?(.+)/) {
	    update_chan($nick, $2, $1);
	}
    }
}

sub on_whoisserver {
    my ($conn, $event) = @_;
    my ($our, $ni, $server) = ($event->args);

    $users{$ni}{'ident'}{'server'} = $server;
}

sub on_end_of_whois {
    my ($conn, $event) = @_;
    my ($our, $who) = ($event->args);

    # Seems like this kind of answer appear on some (inspircd) IRCserver,
    # along with a "no such nick" whois answer.
    return if($who eq '*');

    # $who can be something like nick1,nick2,nick3
    foreach my $ni (split(/,/, $who)) {
	if(update_user_infos($ni) && !$users{$ni}{'welcomed'}) {
	    welcome($ni);
	}
    }
}

# What to do if someone invites the bot somewhere
sub on_invite {
    my ($conn, $event) = @_;
    my ($chan) = $event->args;

    # If someone invites ourselves in the night channel, join it
    if($chan eq $CFG{'night_channel'} || $chan eq $CFG{'day_channel'}) {
	$conn->join($chan);
    }
}

# If the bot tried to join a channel with +i set
sub on_chan_need_invite {
    my ($conn, $event) = @_;
    my ($to, $chan) = $event->args;
    my ($chanserv, $cs_message);

    # If it's the night channel, ask the chan service to invite the bot
    if($chan eq $CFG{'night_channel'}
       && exists($CFG{'hacks'}{'service'}{'chan'})
       && exists($CFG{'hacks'}{'chan'}{'ask_invite'})
       && is_true($CFG{'hacks'}{'chan'}{'ask_invite'})) {
	my $chanserv = $CFG{'hacks'}{'service'}{'chan'}{'nick'};
	if(exists($CFG{'hacks'}{'chan'}{'say'})) {
	    $cs_message = $CFG{'hacks'}{'chan'}{'say'};
	} else {
	    $cs_message = "INVITE ".$chan;
	}

	print "-> Asking ".$chanserv." to invite me in ".$chan."\n";
	say(PRIO_IRC_PROTO, '', $chanserv, $cs_message);
    }
}

# Simply prints that yes, we are the king of IRC!
sub on_im_oper {
    my (undef, $event) = @_;
    print "* I'm oper: ".$event->{args}->[1]."\n";
}

# Exotic 307 numeric is used by the Anope nick service to give the account
# in a /whois response. But it's also used in Undernet for the /USERIP response
# to IRC ops (for normal users it's all the same but using 340 instead of 307).
# USERIP format is: /USERIP (nickname){0,5}
# Answer format is: 307 :(nickname=+userid@ip){0,5}
# E.g.: /USERIP spekkio T_A
# Gives: 307 caller :Spekkio=-Spekkio@209.86.114.238 T_A=-~tomandre@195.204.2.136
sub on_bastard_307 {
    my (undef, $event) = @_;
    my ($our, @stuff) = ($event->args);

    if(@stuff > 1) { # Should be an Anope answer
	$users{$stuff[0]}{'ident'}{'regnick'} = $stuff[0];
    }
}

# We send ourselves CTCP pings to keep alive our connection.
sub on_cping {
    our %timers;
    my ($conn, $event) = @_;
    my ($nick) = $event->nick;
    my ($time) = $event->args;

    if($nick eq $CFG{'nick'}) {
	remove_timer($timers{'deco_checker'}{'cping_timer'});
	$timers{'deco_checker'}{'cping_timer'} = undef;
    }
}

# Link them to the handlers
# We put after each real handler a call to update_last_IRC_recv(), which
# notice there was an IRC activity (used to run pings and detect timeouts).
sub add_handler {
    our $conn;
    my ($event, $code) = @_;
    $conn->add_global_handler($event, sub {
	$code->(@_); update_last_IRC_recv();
    });
}

# End of MOTD or no MOTD = connected
add_handler(['endofmotd', 'nomotd'], \&on_connect);
add_handler('whoreply', \&on_whoreply); # A /who answer
add_handler('public', \&on_public);  # Msg on the channel
add_handler('msg', \&on_public);     # Msg on the channel
add_handler('notice', \&on_notice);  # notice
add_handler('join', \&on_join);      # If someone join
add_handler('nick', \&on_nick);      # If someone change his/her nick
add_handler('namreply', \&on_names); # A "names" line reply
add_handler('part', \&on_part);      # If someone part
add_handler('quit', \&on_quit);      # If someone quit
add_handler('mode', \&on_mode);      # On every mode change
add_handler('kick', \&on_kick);      # If someone gets kicked
add_handler('channelmodeis', \&on_chan_modeinfo); # A channel mode info
add_handler('nicknameinuse', \&on_nick_taken); # nick already taken
add_handler('330', \&on_reg_info);   # Infos about registrated nick
add_handler('whoisuser', \&on_whoisuser); # /whois user info line
add_handler('whoischannels', \&on_whoischannels); # same for channels
add_handler('whoisserver', \&on_whoisserver); # same for server
add_handler('endofwhois', \&on_end_of_whois); # end of /whois
add_handler('invite', \&on_invite); # invited somewhere
add_handler('inviteonlychan', \&on_chan_need_invite);
add_handler('youreoper', \&on_im_oper);
add_handler('307', \&on_bastard_307); # Damn non-standards
add_handler('cping', \&on_cping);

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1


