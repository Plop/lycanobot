# steps.pl
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
# Steps into a game round

our (%CFG, $phase, %messages, %special_jobs, %players, %send_queue, %phs,
     %chanusers);

# This hash describes what to do in all the phases of the game.
# Each phase can have several keys.
#
# who       : Can be "villagers", "werewolves", or any special job. It set
#             who is concerned by this phase. If it's a special job name that is
#             not wanted, the phase is skipped (it goes to the "next" value).
#             In addition, the bot will announce timeout to them, unless it's
#             overriden by "timeout_to" (see below).
# presub    : A coderef called when we enter the phase. The previous phase name
#             we entered in is given as first arg. This sub has to return 1 if
#             we really want to go into the phase, or 0 to go to the "next" one.
#             It may also return a phase name (that is not the current one) if
#             we want to switch to that phase and execute its presub.
# postsub   : A coderef called when we exit the phase.
#             It may return the next phase name, that override the 'next' key.
# timeoutsub: A coderef called when we reach the phase's timeout.
# next      : The next phase name we will go to.
# hide_timeout:Boolean. Controls if the bot to announce the timeout start
#              (default: 0, it's showed). For the timeout reaching, just do
#              not set $messages{'phases'}{$phase}{'timeout'} and it will
#              be hidden.
# timeout_to: Whose to announce the timeout and its reaching.
#             Defaults to the "who" key.
#
# If one of the *sub key is missing, we just do nothing...
our %phases; # Filled by basics.pl

# the steps in game include :
# [night]
# 1(fisrt round only) - call thievish
# 2(fisrt round only) - call cupid

# 3 - seer call
# 4 - werewolves call
# 5 - sorcerer call
# [day]
# pre6 - enventual hunter kill
# 6 - villagers debate and vote
# 6bis - enventual hunter kill
# [night] goto 3

sub push_phase {
    my ($new_phase, $todo) = @_;
    my $remaining = remove_timer($phs{'timer'});
    if(defined($remaining)) {
	$remaining = $remaining->{'time'} - time();
    }

    push(@{ $phs{'stack'} }, { 'current'   => $phs{'current'},
			       'state'     => $phs{'state'},
			       'sub'       => $phs{'sub'},
			       'hooks'     => $phs{'hooks'},
			       'remaining' => $remaining,
			       'todo'      => $todo });

    print "-> Phase cut in ".$phs{'current'}.", state ".$phs{'state'}
         .", sub ".$phs{'sub'}.", going to $new_phase\n";
    $phs{'current'} = $new_phase;
    $phs{'state'}   = 'post'; # go to 'pre' first
    $phs{'sub'}     = 0;
    $phs{'hooks'}   = phs_hooks_init();

    do_next_step();
    return((undef, 1)); # Notice we cutted in the parent do_next_step() call
}

sub pop_phase {
    my $kept = pop(@{$phs{'stack'}});
    my $msg = "-> End of phase cut ".$phs{'current'}.", going back to "
	      .$$kept{'current'}.", state ".$$kept{'state'}
	      .", sub ".$$kept{'sub'};
    $phs{'current'} = $$kept{'current'};
    $phs{'state'}   = $$kept{'state'};
    $phs{'sub'}     = $$kept{'sub'};
    $phs{'hooks'}   = $$kept{'hooks'};
    my $remaining   = $$kept{'remaining'};

    if(defined($remaining)) {
	$msg .= " (".int($remaining)." second(s) remaining)";
	$phs{'timer'} = add_timer($remaining, \&do_phase_timeout);
    } else {
	$phs{'timer'} = undef;
    }
    print $msg."\n";

    &{ $$kept{'todo'} } if(ref( $$kept{'todo'} ) eq 'CODE');
}

sub end_phase {
    my $subs = shift;
    my $phase = $phs{'current'};
    my $p;
    my $cut;
    my $sub;

    if(exists($phases{$phase}{'postsub'})) {
	$subs = $phases{$phase}{'postsub'} unless($subs);
	$subs = [ $subs ] if(ref($subs) eq 'CODE');

	foreach($phs{'sub'} .. $#$subs) {
	    $sub = $$subs[$_];
	    $phs{'sub'} = $_+1;
	    ($p, $cut) = &$sub if(ref($sub) eq 'CODE');
	    return -1 if(defined($cut) && $cut); # The postsub has cut
	}
	$phs{'sub'} = 0;
    }

    if(defined($p) && exists($phases{$p})) { # given by the postsub
	$phs{'current'} = $p;
    } elsif(exists($phases{$phase}{'next'})) { # normal next phase
	$phs{'current'} = $phases{$phase}{'next'};
    }

    return 1;
}

sub begin_phase {
    my $p = 0;
    my $phase = $phs{'current'};
    my $who;
    my $cut;
    my ($sub, $subs);

    while(1) {
	# Do we want that phase ?
	if(exists($phases{$phase}{'who'})
	   && defined($phases{$phase}{'who'})) {
	    $who = $phases{$phase}{'who'};
	    next unless( (exists($special_jobs{$who})
			  && is_true($special_jobs{$who}{'wanted'})
			 ) || !exists($special_jobs{$who}) );
	}
	# We loop until we found no presub ...
	last unless(exists($phases{$phase}{'presub'}));

	$subs = $phases{$phase}{'presub'};
	$subs = [ $subs ] if(ref($subs) eq 'CODE');

	$phs{'current'} = $phase; # In case the presub needs it
	foreach($phs{'sub'} .. $#$subs) {
	    $sub = $$subs[$_];
	    $phs{'sub'} = $_+1;
	    ($p, $cut) = &$sub if(ref($sub) eq 'CODE'); # Run it!
	    return -1 if(defined($cut) && $cut); # The presub has cut
	}
	$phs{'sub'} = 0;
	
	# ... or a presub that returns 1, or the current phase name.
	last if($p && (!exists($phases{$p}) || $p eq $phase));

    } continue {
	# Go to the next step...
	if(exists($phases{$p})) { # given by the presub
	    $phase = $p;

	} elsif(@{$phs{'stack'}}) { # In a phase cut ?
	    return 0; # Get out of that failed phase cut

	} else { # normal next phase
	    $phase = $phases{$phase}{'next'};
	}
    }

    $phase = $p if(exists($phases{$p}));
    $phs{'current'} = $phase;
    return 1;
}

# Go to the next step of the game.
# Arg 1: Bool saying if we want to go again in the phase state we are.
#        Used to come back from a cut-phase.
sub do_next_step {
    my $redo_state = defined($_[0]) ? $_[0] : 0;
    my $prev_phase;
    my $who;

    if(  (!$redo_state && $phs{'state'} eq 'in')      # in -> post
       || ($redo_state && $phs{'state'} eq 'post')) { # in -> cut -> re-in
	if(!$redo_state) {
	    $phs{'state'} = 'post';

	    remove_timer($phs{'timer'}) if(defined($phs{'timer'}));
	    $prev_phase = $phs{'current'};

	    # If we go to the next step whereas the last phase timeout has not
	    # been set yet (i.e. the bot has not said "You have %i seconds" yet)
	    # then delete it from the send queue
	    foreach my $q (keys(%send_queue)) { # delete eventual set_timeout
		foreach(0 .. $#{ $send_queue{$q} }) {
		    next unless(exists($send_queue{$q}->[$_]->{'also_do'}));
		    if($send_queue{$q}->[$_]->{'also_do'}
		       == \&add_timer_timeout) {
			splice(@{ $send_queue{$q} },$_,1);
			last;
		    }
		}
	    }
	}

	# It's the end of the previous phase...
	return if(end_phase() == -1); # postsub has cut

	# If we were into a cut phase, go back into the phase and state we were
	# before the cut happened
	if(@{$phs{'stack'}}) {
	    # Go on in the state loaded by pop_phase()
	    pop_phase();
	    return if(execute_next_hooks()); # It may cut again
	    do_next_step(1); # Go again into state 'post' to do the left stuff
	    return;
	}
	$redo_state = 0; # Comeback in state 'post' done
    }

    # Begining of a new phase...
    if(  (!$redo_state && $phs{'state'} eq 'post')   # post -> pre
       || ($redo_state && $phs{'state'} eq 'pre')) { # post -> cut -> re-post
	if(!$redo_state) {
	    $phs{'state'} = 'pre';

	    remove_timer($phs{'timer'}) if(defined($phs{'timer'}));
	}

	# If we are in a cut phase, we are already in the right phase
	my $ret = begin_phase();
	return if($ret == -1); # presub has cut
	if(!$ret && $phs{'stack'}) {
	    # Cut phase skipped for some reasons...
	    # Go on in the state loaded by pop_phase()
	    pop_phase();
	    return if(execute_next_hooks()); # It may cut again
	    do_next_step(1); # Go again into state 'pre' to do the left stuff
	    return;
	}
	$redo_state = 0; # Comeback in state 'pre' done
    }

    # This state can't be cut
    if($phs{'state'} eq 'pre') { # pre -> in
	$phs{'state'} = 'in';

	print "-> Step changed ";
	print "from $prev_phase " if(defined($prev_phase));
	print "to ".$phs{'current'}."\n";

	# Set the timeout of that new phase :
	if(defined($phases{ $phs{'current'} }{'who'})) {
	    $who = $phases{ $phs{'current'} }{'who'};
	    if($who eq 'villagers') {
		$who = $CFG{'day_channel'};
	    } elsif($who eq 'werewolves') {
		$who = $CFG{'night_channel'};
	    } elsif(exists($special_jobs{$who})
		    && defined($special_jobs{$who}{'nick'})) {
		$who = $special_jobs{$who}{'nick'};
	    }
	    set_phase_timeout($who);
	}
    }
}

# Used by do_next_step(), when we are going back from a phase cut. Because if
# the phase has been cut by a hook, we need to execute the next hooks.
# That simulates several recursive do_action() calls as the stack defines them.
# Returns 1 if the action has been cutted by push_phase().
sub execute_next_hooks {
    my ($args, $cut);

    # We while() around it because do_action() may have pop()'d another action
    while(@{ $phs{'hooks'}{'action_args'} }) {
	(undef, $cut) = do_action();
	return 1 if($cut);
    }
    return 0;
}

sub add_timer_timeout {
    our %game_sets;
    my $timeout = $game_sets{'timeouts'}{ $phs{'current'} };
    # $_[0] is the current time
    $phs{'timer'} = add_timer_at($_[0] + $timeout, \&do_phase_timeout);
    print "-> Set next timeout to happen in $timeout seconds\n";
}

# Set a timeout to occur for the current phase, if there is any.
# The bot will wait until the phase timeout is reached.
# Unique arg is where/to who it will be announced 
sub set_phase_timeout {
    our %game_sets;
    my $to = shift;
    my $timeout;
    my $phase = $phs{'current'};
    my $msg;

    return unless(exists($game_sets{'timeouts'}{$phase}));
    $timeout = $game_sets{'timeouts'}{$phase};

    # Announce any timemout
    # The timeout announce is put in queue so that it will occur
    # exactly after the bot said it.
    if($timeout != 0) {
	# Do we want that timeout to be announced ?
	if(( exists($phases{$phase}{'hide_timeout'})
	     && !$phases{$phase}{'hide_timeout'} )
	   || !exists($phases{$phase}{'hide_timeout'}) ) {
	    
	    if(exists($phases{$phase}{'timeout_to'})) {
		$to = $phases{$phase}{'timeout_to'};
	    }

	    if(exists($messages{'phases'}{$phase}{'timeout_announce'})) {
		($msg) = say(P_GAMEADV, 'info', read_ply_pnick($to),
		    $messages{'phases'}{$phase}{'timeout_announce'}, $timeout);
	    } else {
		($msg) = say(P_GAMEADV, 'info', read_ply_pnick($to),
		    $messages{'timeout_announce'}{'default'}, $timeout);
	    }
	    # Attach the do_phase_timeout() sub, to happen later
	    $msg->{'also_do'} = \&add_timer_timeout;
	} else {
	    # Hidden timeout, make it start now
	    $phs{'timer'} = add_timer($timeout, \&do_phase_timeout);
	    print "-> Set next timeout to happen in $timeout seconds\n";
	}
    }
}

# Handles phases timeouts.
sub do_phase_timeout {
    our %votes; # for the default_vote_timeout()
    my $phase = $phs{'current'};
    my $to;
    my $talkto = $CFG{'day_channel'};
    my $do_nothing = 0;

    if(exists($phases{$phase}{'who'})) {
	$to = $phases{$phase}{'who'};
    }
    if(exists($phases{$phase}{'timeout_to'})) {
	$to = $phases{$phase}{'timeout_to'};
    }

    if(exists($phases{$phase}{'timeoutsub'})
       && ref($phases{$phase}{'timeoutsub'}) eq 'CODE') {
	# Execute the $phase timeout code
	&{ $phases{$phase}{'timeoutsub'} };

    } elsif(exists($votes{$phase})) {
	default_vote_timeout();
    }

    # Say a timeout has been reached if possible
    if(defined($to)) {
	if($to eq 'villagers') {
	    $talkto = $CFG{'day_channel'};
	} elsif($to eq 'werewolves') {
	    $talkto = $CFG{'night_channel'};
	}
	if(exists($messages{'phases'}{$phase}{'timeout'})) {
	    if(exists($special_jobs{$to}{'nick'})) {
		$talkto = read_ply_pnick($special_jobs{$to}{'nick'});
	    }
	    
	    # Such messages are always game-related, right ?
	    say(P_GAMEADV, 'info', $talkto,
		$messages{'phases'}{$phase}{'timeout'});
	}
    }

    do_next_step();
}    

# The default sub for a vote timeout. It first check the votes a last time, 
# and if someone is designated by this vote, it executes the 'endsub' on him.
# If none is designated by the votes, it choose a random player, and executes
# the 'endsub' on it.
sub default_vote_timeout {
    our %votes;
    my $victim;
    my $chan = $CFG{ $votes{ $phs{'current'} }{'chan'} };
    my $vote = check_votes(\$victim);

    # Check the votes a last time
    if($vote == -1 || ($vote == 0 && !defined($victim)) ) {
	$victim = choose_random_player();
	return 0 unless(defined($victim));

	say(P_GAMEADV, 'info', $chan,
	    $messages{'timeouts'}{'random'}, $victim);
    } else {
	say(P_GAMEADV, 'info', $chan,
	    merge_votemsg($messages{'timeouts'}{'vote'}), $victim);
    }

    # Execute the endsub on him if possible
    if(ref($votes{ $phs{'current'} }{'endsub'}) eq 'CODE') {
	$votes{ $phs{'current'} }{'endsub'}->($victim);
    }
}

# Chooses a random alive player. Used in timeouts.
# Any args are players names we don't want to pick up.
sub choose_random_player {
    my (@avoid) = @_;
    my @targs = grep { my $p = $_; !grep { $p eq $_ } @avoid } alive_players();

    # Check if there is at least one player we can choose
    return undef unless(@targs);

    # Choose a random alive player
    return $targs[rand(@targs)];
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1
