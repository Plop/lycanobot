# admin.pl
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
# administration stuff

our (%CFG, %chanmode, %users, %chanusers, %players, @userlist,
     %special_jobs, %messages);

# Checks if someone is admin or moderator
# arg 1: type of privilege ('admins' or 'moderators')
# arg 2: the person's nick.
# return 1 if he's admin or 0 if not
sub has_privilege {
    my ($privi, $nick) = @_;
    my $str;
    my $irc_ident;

    return 0 unless(exists($CFG{$privi}));

    # Check for masks
    foreach(@{$CFG{$privi}{'mask'}}) {
	if(/.+!.+@.+/) {
	    $irc_ident = $nick.'!'.$users{$nick}{'ident'}{'user'}.'@'
	      .$users{$nick}{'ident'}{'host'};
	    if(defined($users{$nick}{'ident'}{'domain'})) {
		$irc_ident .= $users{$nick}{'ident'}{'domain'};
	    }
	    
	    $str = $_;
	    # build the regexp
	    $str = quotemeta($str); # add backslashes metachars
	    # replace backslashes by dots before quantifier '*'
	    $str =~ s/\\(\*)/\.$1/g;
	    return 1 if($irc_ident =~ /$str/);
	}
    }
    # Check for registered nicks
    foreach(@{$CFG{$privi}{'regnick'}}) {	
	if (defined($users{$nick}{'ident'})
	    && defined($users{$nick}{'ident'}{'regnick'})) {
	    return 1 if($_ eq $users{$nick}{'ident'}{'regnick'});
	}
    }
    return 0;
}

# Check if someone is ignored in the config file
# arg 1 : the nick of the user
# Return 1 if ignored, 0 if not
sub is_ignored {
    return grep({$_ eq $_[0]} @{$CFG{'ignore'}});
}

# This sub initialize a new game distributing jobs
# to every player (so %players is reseted)
# $1 = number of werewolves
sub initialize_players {
    our %game_sets;

    my $num_werewolves = shift;
    my @cards; # cards to distribute
    my $rand;
    my ($i,$j);
    my $num_players = keys(%players);
    my $min_ply;
    my $job;

    # First, set %special_jobs as the game style says, if any
    if($game_sets{'jobs'}{'style'}) {
	unless(apply_jobs_style($game_sets{'jobs'}{'style'}, $num_players)) {
	    say(P_GAMEADMIN, 'error', $CFG{'day_channel'},
		$messages{'outgame'}{'style_denied_start'},
		$game_sets{'jobs'}{'style'}, $num_players);
	    return 0;
	}
    } else { # otherwise use the users'custom settings
	foreach(keys(%special_jobs)) {
	    $special_jobs{$_}{'wanted'} = $game_sets{'jobs'}{'wanted'}{$_};
	}
    }

    # Add specials villagers
    foreach(keys(%special_jobs))
    {
	next if(exists($special_jobs{$_}{'distribute'})
		&& !$special_jobs{$_}{'distribute'});
	# Is this feature wanted ?
	push(@cards, $_) if($special_jobs{$_}{'wanted'});
    }

    # Here @cards contains only the special jobs. And that the last thing we
    # need to see if there are enouth players.
    $min_ply = @cards / (1-$CFG{'werewolves_proportion'});
    $min_ply = int(0.5 + $min_ply); # means round()

    if($num_players < $min_ply) {
	# Build the needed jobs string
	my $needed = "$num_werewolves ";
	$needed .= $num_werewolves > 1 ?
	    $messages{'team_name'}{'werewolves'} : 
	    $messages{'team_name'}{'werewolf'};
	$needed .= ', ';

	foreach(0..$#cards-1) {
	    $needed .= $messages{'jobs_name'}{ $cards[$_] }.', ';
	}
	$needed .= $messages{'jobs_name'}{ $cards[-1] };

	say(P_GAMEADMIN, 'error', $CFG{'day_channel'},
	    $messages{'outgame'}{'not_enouth_players'}, $min_ply, $needed);
	return 0;
    }

    # Add werewolves
    for (1 .. $num_werewolves)
    { push(@cards, 'werewolf'); }
    
    # Pad with normal villagers
    for(@cards .. $num_players-1) {
	push(@cards, 'villager');
    }

    # mix up the cards :)
    # this shuffle @cards
    foreach (1 .. 5) {
	$i = @cards;
	while(--$i) {
	    $j = int rand($i+1);
	    next if $i == $j;
	    @cards[$i,$j] = @cards[$j,$i];
	}
    }

    # Initialize all players, assinging each job
    foreach(keys(%players))
    {
	$job = pop(@cards);
	$players{$_}{'job'} = $job;
	$players{$_}{'alive'}    = 1;
	$players{$_}{'answered'} = 0;
	if(exists $special_jobs{$job}) {
	    $special_jobs{$job}{'nick'} = make_ply_pnick($_);
	}
	if($job eq 'werewolf') {
	    $players{$_}{'team'} = 'werewolves';
	} else {
	    $players{$_}{'team'} = 'villagers';
	}
    }

    # Execute jobs initsubs
    foreach my $job (keys(%special_jobs)) {
	next unless($special_jobs{$job}{'wanted'});
	if(exists($special_jobs{$job}{'initsub'})
	   && ref($special_jobs{$job}{'initsub'}) eq 'CODE') {
	    $special_jobs{$job}{'initsub'}->($special_jobs{$job});
	}
    }
    return 1;
}

# Initialize a %players entry with the basics things
sub init_player {
    my $ni = shift;
    $players{$ni} = {
	'nick'        => $ni,
	'connected'   => 1,
	'alive'       => 1,
	'job'         => undef,
	'team'        => undef,
	'answered'    => 0,
	'vote_weight' => 1
	};
    #$players{$ni}{'vote'} doesn't exists unless the player actually vote
    #$players{$ni}{'deco_timer'} doesn't exists unless the player disconnects
    #$players{$ni}{'spoof'} doesn't exists unless the player spoofs anyone
}


# (de)voice players
# $1 = message priority
# $2 = chan
# $3 = '+' or '-' (voice or devoice)
# $4 can be 'players','alives','werewolves', or nothing for everybody
sub voice_them {
    my ($prio,$chan,$sign,$who) = @_;
    my @users;  # users waiting to be voiced
    $who = 'all' unless(defined($who));

    foreach(keys(%{ $chanusers{$chan} })) {
        next if((!$chanusers{$chan}{$_}{'voiced'}) && ($sign eq '-'));
        next if(( $chanusers{$chan}{$_}{'voiced'}) && ($sign eq '+'));
	next if($_ eq $CFG{'nick'});

	if(!exists($players{$_})) {
	    next if($who ne 'all' );
	} else {
	    next if(($who eq 'alives' || $who eq 'werewolves')
		    && !$players{$_}{'alive'});
	    next if($who eq 'werewolves' && $players{$_}{'job'} ne 'werewolf');
	}
        push(@users, $_);
        next if(@users % $CFG{'max_mode_params'} != 0);

        mode($prio, $chan, $sign.'v'x@users, @users);
        for(1..$CFG{'max_mode_params'}) {
	    pop(@users);
	}
    }
    return if($#users == -1);

    # (de)voice the rest too if needed
    mode($prio, $chan, $sign.'v'x@users, @users);
}

# Makes everything to exclude properly a player who went out
# $1 = nick on the excluded player
# $2(only on /part and /quit) = part or quit message
# $3(only if he part from a channel, not the server) = channel name
#
# A user is assumed to be here if he is in the day channel.
sub exclude_ply {
    our $in_game;
    my ($ni, $quit_msg, $chan) = @_;
    $chan = '' unless(defined $chan);
    my $infos = get_infos($ni);

    # Clean %chanusers
    if($chan eq '') {
	foreach(keys(%chanusers)) {
	    delete $chanusers{$_}{$ni};
	}
    } else {
	delete $chanusers{$chan}{$ni};
    }

    # Ignore exclusion of users we don't known
    return unless(exists($users{$ni}));
    
    my $private = $users{$ni}{'private'};
    $private = $$private if(ref($private) eq 'REF');

    # What to do if the user is no more here
    if(!exists($chanusers{ $CFG{'day_channel'} }{$ni})
	&& ($chan eq '' || $chan eq $CFG{'day_channel'})) {
	# Don't keep personal informations of unidentified users
	my @idents;
	my $i = get_user_by_priv($private);
	if($i >= 0) {
	    # Is it identless ?
	    @idents = keys(%{$userlist[$i]});
	    @idents = grep(!/^lycainfo$/, @idents);
	    unless(@idents) {
		splice(@userlist, $i, 1);
		print "-> Forgotten user $ni (got nothing to ident him)\n";
	    }
	}

	# Clean %users
	delete $users{$ni};

	# Update this user's data
	$$infos{'last_seen'} = int(time()); # last time saw
	if($$infos{'hlme'} eq 'quit') {
	    # Disable hl'ing of this user if he wanted that until quit
	    $$infos{'hlme'} = 'never';
	}
	write_user_infos();

	if(exists($players{$ni})) {
	    # If the user nick was spoofed, consider the spoofer nick
	    # instead of the spoofed one
	    if(defined($players{$ni}{'spoof'})) {
		# Player excluded, so no spoofing can be done anymore
		$ni = delete $players{$ni}{'spoof'};
	    }
	}

	# Handle things if that happened while in game or in wait_play
	if(exists($players{$ni}) && $players{$ni}{'connected'}) {
	    
	    # Recovery can only be do while in game.
	    if(!$in_game) {
		# We are in wait_play
		delete $players{$ni};
		return;
	    }

	    $players{$ni}{'connected'} = 0;

	    # Only alive players can be recovered
	    return unless($players{$ni}{'alive'});

	    # Check if we want to recover such quit
	    my $recover = 0;
	    if(defined($quit_msg) && ref($CFG{'quit_recovery'}{'recover'}) eq 'ARRAY') {
		my ($on, $msg, $regexp);
		foreach(@{$CFG{'quit_recovery'}{'recover'}}) {
		    ($on,$msg,$regexp) = ($$_{'on'}, $$_{'msg'}, $$_{'regexp'});
		    if(($on eq 'part' && $chan ne '')
		       || ($on eq 'quit' && $chan eq '')) {
			if(defined($msg)) {
			    $recover = 1, last if($quit_msg eq $msg);
			}
			if(defined($regexp)) {
			    if(eval "grep $regexp, (\$quit_msg)") {
				$recover = 1; last;
			    }
			}
		    }
		}
	    }

	    # Recovery possible, in game (therefore not in wait_play)
	    if($recover && ref($private) eq 'HASH') {
		# See if there are any clones lying around
		my $clone;
		foreach(keys(%users)) {
		    next unless(ref($users{$_}{'private'}) eq 'REF');
		    if(${$users{$_}{'private'}} eq $private # clone
		       && !exists($players{$_})) { # not playing
			$clone = $_;
			last;
		    }
		}

		if(defined($clone)) {
		    ressurect_ply($clone, $ni);
		} else {
		    my $back = '';
		    # Save its nick for later recovery
		    $$private{'lycainfo'}{'game_nick'} = $ni;
		    if($CFG{'quit_recovery'}{'wait'} > 0) {
			$back = " (if back before "
			    .$CFG{'quit_recovery'}{'wait'}." second(s))";
			# Run a timer, we wait for him a certain amount of time
			$players{$ni}{'deco_timer'}
			= add_timer
			    ($CFG{'quit_recovery'}{'wait'},
			     sub {
				 say(P_GAMEADMIN, 'info', $CFG{'day_channel'},
				     $messages{'timeouts'}{'lost_player'},
				     $_[0]);
				 do_loose_player($_[0]);
			     },
			     $ni);
 		    }
		    print "-> Player $ni will be recovered$back\n";
		}
	    }
	    # No recovery, and we are in game (therefore not in wait_play)
	    else {
		# not a good end, but a quit is a quit
		do_loose_player($ni);
	    }
	}
    }
}

sub do_loose_player {
    my $ni = shift;

    # Just kill him...
    $players{$ni}{'alive'} = 0;
    do_action('death_announce', $ni);
    do_action('check_win', 'end');
    if(read_last_action_result('check_win')) {
	do_action('end_game');
    }
}

# Helps exclude_ply()
# Arg 1: ref to a $userhost[n]
sub get_user_by_priv {
    my ($priv) = @_;

    foreach(0 .. $#userlist) {
	# Find the element number in @userlist
	# of that $users{$ni}{'private'}
	if(ref($priv) eq 'REF' && $userlist[$_] eq $$priv) {
	    return $_;
	}
    }
    return -1;
}

# make the game ends
# It's registered as the 'end_game' action, so that normally you would
# call it from a phase sub or an action hook using something like:
#    do_action('check_win', 'end');             # check and say the end, if any
#    if(read_last_action_result('check_win')) {
#        return do_action('end_game');          # end_game() and stop everything
#    }
sub end_game {
    reset_game_vars(); # flush vars

    # Delete the timers of disconnected players
    remove_deco_timer($_) foreach(keys(%players));

    # Kill everybody and reset the game-related informations
    foreach(keys(%players)) {
	delete $players{$_};
    }

    print "-> Game ended.\n";

    voice_them(P_GAMEADV, $CFG{'day_channel'}, '-');
    unless(is_true($CFG{'use_random_night_channel'})) {
	voice_them(P_GAMEADV, $CFG{'night_channel'}, '-');
    }

    # Should demoderates the channel and allow nick changes
    mode_hook(P_GAMEADV, 'end_game');

    if(is_true($CFG{'use_random_night_channel'})) {
        change_night_channel();
    }
    # We put a cut flag here so that this action will stop everything
    return ((undef, 1));
}

# This sub kick everybody from $CFG{'night_channel'} and invite the werewolves.
sub purge_night_chan {

    foreach (keys(%{ $chanusers{$CFG{'night_channel'}} })) {
	next if($_ eq $CFG{'nick'});
	kick(P_GAMEADMIN, $CFG{'night_channel'}, $_,
	     $messages{'kick'}{'restart_game'}, $CFG{'day_channel'});
    }
    
    # Then invite the werewolves or force them to join using /SAJOIN
    if(exists($CFG{'hacks'}{'command'})
       && ref($CFG{'hacks'}{'command'}) eq 'ARRAY' # Avoid fatal deref error
       && grep( {$_ eq 'sajoin'} @{ $CFG{'hacks'}{'command'} })) {
	foreach(alive_players()) {
	    if($players{$_}{'job'} eq 'werewolf') {
		my $pnick = make_user_pnick($_);
		raw_line(sub {
		   return "SAJOIN ".read_user_pnick($pnick)." ".$CFG{'night_channel'}
			 });
	    }
	}

    } else { # Politely invite them
	foreach(alive_players()) {
	    if($players{$_}{'job'} eq 'werewolf') {
		say(P_GAMEADV, 'query', $_,
		    $messages{'outgame'}{'invite_werewolf'}, 
		    $CFG{'night_channel'}, $CFG{'night_channel'});
		invite(P_GAMEADV, $_, $CFG{'night_channel'});
	    }
	}
    }
}

# Do mode, but also check if it's not useless :
# return 1 if at least one mode has been queued
# or 0 if no modes has been queued (all given were already sets)
sub mode {
    my ($prio, $to, $mode, @rest) = @_;
    my $minus_modes = $mode;
    $minus_modes =~ s/\+[a-zA-Z]+//g; # delete +'ed modes
    $minus_modes =~ s/\-//g; # deletes '-' signs
    my $plus_modes = $mode;
    $plus_modes =~ s/\-[a-zA-Z]+//g; # deletes -'ed modes
    $plus_modes =~ s/\+//g; # deletes '+' signs
    @rest = () unless(@rest);
    my $t;

    # Avoid setting channel modes already sets
    if(exists($chanmode{$to}) && $#rest == -1) {
	foreach (split("", $plus_modes)) {
	    if($chanmode{$to} =~ /\Q$_/) {
		$plus_modes =~ s/\Q$_//;
		$mode =~ s/\Q$_//;
	    }
	}
	foreach (split("", $minus_modes)) {
	    if($chanmode{$to} !~ /\Q$_/) {
		$minus_modes =~ s/\Q$_//;
		$mode =~ s/\Q$_//;
	    }
	}
	$mode =~ s/[\+\-]+([\+\-])/$1/g; # delete contigous + or -
    }

    return 0 if($mode eq '-' || $mode eq '+'); # all given mode already set

    # If just asking for a channel's modes,
    # add a fake mode to set a minimum wait time
    $minus_modes = "." if($mode eq "");

    $t = ( $CFG{'mode_speed'} == 0 ? 0 :
	   (length($minus_modes) + length($plus_modes))/$CFG{'mode_speed'} );
    # Modes are part of the game and well-inserted into others messages
    push_on_sendqueue($prio,
	 {'type' => 'mode',
	  'to'   => $to,
	  'txt'  => [ $mode, map { make_user_pnick($_) } @rest ],
	  'time' => $t
	  }
	 );
    return 1;
}

# Handles modes hooks
# $prio is the mode message priority
# $hook can be chanop, end_game, begin_game or end_game.
# $dst (optionnal) can be day_channel, night_channel, ourself or undef for all
sub mode_hook {
    my ($prio, $hook, $dst) = @_;
    my $to;

    my %dst_conv =
	( 'day_channel' => $CFG{'day_channel'},
	  'night_channel' => $CFG{'night_channel'},
	  'ourself' => $CFG{'nick'} );

    unless($hook eq 'chanop' || $hook eq 'connect'
	   || $hook eq 'begin_game' || $hook eq 'end_game') {
	print "# warning: invalid mode hook: '".$hook."'\n";
	return;
    }

    if(ref($CFG{'mode'}) eq 'ARRAY') { # Avoid fatal invalid dereferences
	foreach(@{ $CFG{'mode'} }) {
	    next unless($hook eq $$_{'on'});
	    next if(defined($dst) && $dst ne $$_{'to'});

	    unless(exists($dst_conv{ $$_{'to'} })) {
		print '# warning: invalid mode hook destination: `'
		    .$$_{'to'}."'\n";
		next;
	    }
	    mode($prio, $dst_conv{ $$_{'to'} }, split(/ +/, $$_{'content'}));
	}
    }
}

# Return an array with the nick of all the alive players
sub alive_players {
    my @aplayers;

    foreach(keys(%players)) {
	push(@aplayers, $_) if($players{$_}{'alive'});
    }
    return @aplayers;
}

# Return an array with the nick of all the alive players who can vote,
# for the current vote phase
sub alive_voters {
    our (%phs, %votes);
    my @vplayers;

    return unless(exists($votes{ $phs{'current'} }));

    my $chan = $votes{ $phs{'current'} }{'chan'};
    $chan = $CFG{$chan};
    foreach(alive_players()) {
	next if($phs{'current'} eq 'werewolf'
		&& $players{$_}{'job'} ne 'werewolf');
	next unless(exists($chanusers{$chan}{$_})); # Avoid disconnected ones

	# players with vote_weight == 0 are discarded
	push(@vplayers, $_) if($players{$_}{'vote_weight'} > 0);
    }
    return @vplayers;
}

# Do everything a disconnected player who come back needs
# Arg 1: the current player nick
# Arg 2: the nick the player had when he disconnected
sub ressurect_ply {
    our (%phs, %timers);
    my ($ni, $game_ni) = @_;

    return unless(exists($players{$game_ni}));

    if($ni ne $game_ni && exists($players{$ni}{'deco_timer'})) {
	# Going here means the new nick is currently owned by
	# another waited player. It's clearly a spoof attempt.
	slap_spoofer($game_ni, $ni, $ni);
	return;
    }

    remove_deco_timer($game_ni);

    return unless($players{$game_ni}{'alive'}); # Killed while not here.. unfair

    if($ni eq $game_ni) {
	print "-> Recognized player $ni, resurrecting\n";
	say(P_GAMEADMIN, 'info',$CFG{'day_channel'},
	    $messages{'welcome'}{'back'}, $ni);
    } else {
	print "-> Recognized player $ni (previously $game_ni), resurrecting\n";
	$players{$ni} = delete $players{$game_ni};
	$players{$ni}{'nick'} = $ni;
	say(P_GAMEADMIN, 'info', $CFG{'day_channel'},
	    $messages{'welcome'}{'back_new_nick'}, $ni, $game_ni);
    }

    $players{$ni}{'connected'} = 1;

    # If he's a werewolf reinvite him, or /SAJOIN him
    if(our $in_game && $players{$ni}{'job'} eq 'werewolf') {
	if(exists($CFG{'hacks'}{'command'})
	   && ref($CFG{'hacks'}{'command'}) eq 'ARRAY' # Avoid fatal deref error
	   && grep({$_ eq 'sajoin'} @{ $CFG{'hacks'}{'command'} })) {
	    my $pnick = make_user_pnick($ni);
	    raw_line(sub {
		return "SAJOIN ".read_user_pnick($pnick)." ".$CFG{'night_channel'}
		     });

	} else { # Politely invite them
	    say(P_GAMEADV,'query',$ni,$messages{'outgame'}{'invite_werewolf'}, 
		$CFG{'night_channel'}, $CFG{'night_channel'});
	    invite(P_GAMEADV, $ni, $CFG{'night_channel'});
	}
    }

    # Voice if needed
    if($phs{'current'} eq 'day' || $phs{'current'} eq 'wait_play'
       || $phs{'current'} eq 'hunter') {
	mode(P_GAMEADV, $CFG{'day_channel'}, '+v', $ni);
    }
}

# What to do with player nick spoofers.
# Since $players{$spoofed}{'spoof'} is created, $spoofed will not be able to
# run commands until he is kicked.
sub slap_spoofer {
    my ($spoofer, $spoofed, $kick) = @_;
    kick(P_GAMEADMIN, $CFG{'day_channel'}, $kick,
	 $messages{'kick'}{'nick_spoof'}, $spoofer, $spoofed);
    $players{$spoofed}{'spoof'} = $spoofer;
    print "# warning : $spoofer tries to spoof player $spoofed"
	 .", gonna kick him\n";
}

# Removes any deconnection timer on a player
sub remove_deco_timer {
    my $ni = shift;
    if(exists($players{$ni}{'deco_timer'})) {
        remove_timer(delete $players{$ni}{'deco_timer'});
    }
}

# Begins the night channel changing process
sub change_night_channel {
#    # Empty the old night channel
#    foreach (keys(%{ $chanusers{$CFG{'night_channel'}} })) {
#        next if($_ eq $CFG{'nick'});
#        kick(P_GAMEADV, $CFG{'night_channel'}, $_, $messages{'kick'}{'end_game'});
#    }
    part(P_GAMEADV, $CFG{'night_channel'});
    # The following takes place in on_part
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1
