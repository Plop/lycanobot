# basics.pl
# Copyright (C) 2009  Gilles Bedel
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
# basic stuff needed for the game

our (%messages, %CFG, %players);

# Here are some phases & actions
sub load_game_basics {
    # Set the basic phases
    our %phases =
 ( 'no_game' => {
     'who'   => 'villagers',
     'next'  => 'wait_play'
   },
   'wait_play' => {
     'who'        => 'villagers',
     'presub'     => \&pre_wait_play,
     'postsub'    => \&post_wait_play,
     'next'       => 'wait_werewolves'
   },
   'wait_werewolves' => {
     'who'        => 'villagers',
     'hide_timeout'=> 1,
     'next'       => 'captain'
   },
   # A virtual phase in which we only begin_round() and go directly to cupid.
   '_begin_round' => { 
     'who'        => 'villagers',
     'presub'     => \&begin_round,
     'next'       => 'cupid'
   },
   'day' => {
     'who'        => 'villagers',
     'presub'     => [ \&pre_day1, \&pre_day2 ],
     'postsub'    => [ \&post_day1, \&post_day2 ],
     'next'       => '_begin_round'
   },
   'werewolf' => {
     'who'        => 'werewolves',
     'presub'     => \&pre_werewolves,
     'postsub'    => \&post_werewolves,
     'timeoutsub' => \&timeout_werewolves,
     'next'       => 'sorcerer'
   }
 );

    # Basic actions, without any hook
    our %actions =
	( 'kill' => { 'sub' => \&do_kill },
	  'death_announce' => {
	      'sub' => \&announce_death_job # in speech.pl
	  },
	  'morning_death_announce' => {
	      'sub' => \&do_morning_death_announce
	  },
	  'save'        => { 'sub' => \&do_save },
	  'vote'        => { 'sub' => \&do_vote },
	  'vote_result' => { 'sub' => \&do_vote_result },
	  'check_win'   => { 'sub' => \&do_check_win },
	  'end_game'    => { 'sub' => \&end_game }
	);
    foreach(keys(%actions)) {
	$actions{$_}{'hooks'} = {};
    }

    # Votes phases
    # A hash describing where and when the votes takes place.
    # Its keys are the phases names with votes, which contains some infos:
    #  chan     : a ref to the chan where the vote takes place
    #  purpose  : 'for' or 'against', depending of what the players vote for
    #  teamvote : boolean that allows voting for teammates
    #  endsub   : a coderef to execute when the vote is concluded.
    #             The designated player is given as first arg.
    #  external : flag that means the votes were loaded from an extrernal file.
    our %votes =
(
    'day' => {
	'chan'     => 'day_channel',
	'purpose'  => 'against',
	'teamvote' => 1,
	'endsub'   => sub { do_action('kill', 'villager', $_[0]); }
    },
    'werewolf' => {
	'chan'     => 'night_channel',
	'purpose'  => 'against',
	'teamvote' => 0,
	'endsub'   => sub { do_action('kill', 'werewolf', $_[0]); }
    }
);

    # No special jobs initially
    our %special_jobs = ();

    # No actions auth
    our %actions_auth = ();

    # No special jobs
    our %last_actions = ();
}

## Associated phase subs
# wait_play phase
sub pre_wait_play {
    my $to = $CFG{'day_channel'};
    ask_for_cmd($to, $to, 'play');
    return 1;
}

sub post_wait_play {
    # Now, if the game can be started, we start it and
    # we will wait for the werewolves to join their channel
    if(!init_game()) {
	return do_action('end_game');
    }

    # If all the werewolves have already joined let's start
    return 'wait_werewolves' if(have_werewolves_joined());
}

# _begin_round phase

# A sub used in the _begin_round phase
sub begin_round {
    do_action('check_win', 'end');
    if(read_last_action_result('check_win')) {
	return do_action('end_game');
    }

    say(P_GAMEADV, 'info', $CFG{'day_channel'},
	$messages{'time_to'}{'village_sleep'});
    # devoice everyone in the chan
    voice_them(P_GAMEADV, $CFG{'day_channel'}, '-');
    our $round++;
    # This "return" means we don't really go in this phase, it's a virtual one.
    return 0;
}

## Day phase
# The presub is splitted into 3 pieces, in order to allow any event called by
# a do_action('death_announce', ...) to cut the phase using push_phase()
sub pre_day1 {
    our %last_actions;
    my $prev_phase = shift;
    my $num_killed = 0;
    my $to = $CFG{'day_channel'};
    my ($killer, $victim);

    # Count the number of killed
    foreach(values(%{$last_actions{'kill'}})) {
	next unless(defined($_));
	$num_killed++;
    }
    foreach(values(%{$last_actions{'save'}})) {
	$num_killed-- if(defined($_));
    }
    
    # Announce the number of killed
    if($num_killed == 0) {
	say(P_GAMEADV, 'info',$to, $messages{'deads'}{'morning_no_dead'});
	
    } elsif($num_killed == 1) {
	say(P_GAMEADV, 'info',$to, $messages{'deads'}{'morning_one_dead'});
	
    } elsif($num_killed == 2) {
	say(P_GAMEADV, 'info',$to, $messages{'deads'}{'morning_two_deads'});
    }
    
    # Announce what horrible things happened last night
    # The default action is the werwolves death announce, which may have
    # "before" or "after" hooks for other deaths.
    return do_action('morning_death_announce');
}

sub pre_day2 {
    # reset all kills & save. Saves are deleted when announced, but some of
    # those may not have been announced. This happens when more than one
    # save targets the same player (e.g. sorcerer cure and rescuer protection).
    delete_last_action_result('kill');
    delete_last_action_result('save');

    my $to = $CFG{'day_channel'};

    ## Normal day beginning, call the villagers
    # Check if werewolves or villagers wins :
    do_action('check_win', 'end');
    if(read_last_action_result('check_win')) {
	return do_action('end_game');
    }
    
    say(P_GAMEADV, 'query',$to, $messages{'time_to'}{'find_werewolves'});
    ask_for_cmd($to, $to, 'vote');
    voice_them(P_GAMEADV, $to, '+', 'alives');
    return 1;
}

sub post_day1 {
    our $round;
    my $villagers_kill = read_ply_pnick
	(read_last_action_result('kill','villager'));

    if($round != 0) { # Not in the beginning of a game
	# End of villagers'vote, reset them
	foreach(keys(%players)) {
	    $players{$_}{'answered'} = 0;
	    delete $players{$_}{'vote'};
	}
	
	return unless(defined($villagers_kill));
	say(P_GAMEADV, 'reply', $CFG{'day_channel'},
	    $messages{'deads'}{'villagers_kill'},
	    $villagers_kill);
	do_action('death_announce', $villagers_kill);
    }
}

sub post_day2 {
    delete_last_action_result('kill', 'villager');

    do_action('check_win', 'end');
    if(read_last_action_result('check_win')) {
	return do_action('end_game');
    }
}

sub timeout_day {
    my $victim;
    my $vote = check_votes(\$victim);

    # Check the votes a last time
    if($vote == -1 || ($vote == 0 && !defined($victim)) ) {
	$victim = choose_random_player();
	return 0 unless(defined($victim));

	say(P_GAMEADV, 'info', $CFG{'day_channel'},
	    $messages{'timeouts'}{'random'}, $victim);
    } else {
	say(P_GAMEADV, 'info', $CFG{'day_channel'},
	    merge_votemsg($messages{'timeouts'}{'vote'}), $victim);
    }
    do_action('kill', 'villager', $victim); # kill her/him
}

## Werewolf phase
sub pre_werewolves {
    my $to = $CFG{'night_channel'};

    voice_them(P_GAMEADV, $to, '+','werewolves');
    say(P_GAMEADV, 'query',$to, $messages{'time_to'}{'werewolves_kill'});
    ask_for_cmd($to, $to, 'vote');
    announce_targs($to, 'non-werewolves');
    return 1;
}

sub post_werewolves {
    my $victim = read_ply_pnick
	(read_last_action_result('kill','werewolf'));

    # End of werewolves'vote, reset them
    foreach(keys(%players)) {
	$players{$_}{'answered'} = 0;
	delete $players{$_}{'vote'};
    }

    if(length($victim)) {
	say(P_GAMEADV, 'reply', $CFG{'night_channel'},
	    $messages{'deads'}{'werewol_u_kill'}, $victim);
	voice_them(P_GAMEADV, $CFG{'night_channel'},'-','werewolves');
    } else {
	# No werewolves'victim, they hunger to death
	do_action('check_win', 'end');
	if(read_last_action_result('check_win')) {
	    return do_action('end_game');
	}
    }
}

sub timeout_werewolves {
    my $victim;
    my $vote = check_votes(\$victim);

    # Check the votes a last time
    if($vote == -1 || ($vote == 0 && !defined($victim)) ) {
	# werewolves die of hunger if they can't choose any victim
	# because of equal votes or nobody voted
	say(P_GAMEADV, 'info', $CFG{'night_channel'},
	    $messages{'timeouts'}{'werewolf_die_hunger'});
	foreach(alive_players()) {
	    do_action('kill', undef, $_) if($players{$_}{'job'} eq 'werewolf');
	}
	say(P_GAMEADV, 'info', $CFG{'day_channel'},
	    $messages{'deads'}{'werewol_die_hunger'});

	# Undefined victim. Processing this will be done in post_werewolves().
	write_last_action_result('', 'kill', 'werewolf');

    } else {
	say(P_GAMEADV, 'info', $CFG{'night_channel'},
	    merge_votemsg($messages{'timeouts'}{'vote'}), $victim);
	do_action('kill', 'werewolf', $victim); # kill her/him
    }
}

## Game actions

# kill someone
# $1 = nick of the one killed
# $2(optional) = cause of the dead (actually the $last_actions{kill} key)
sub do_kill {
    my ($cause, $victim) = @_;

    if(! $players{$victim}{'alive'}) {
	print '# warning : attempting to kill someone already killed ('
	  .$victim.")\n";
	return 0;
    }

    $players{$victim}{'alive'} = 0;
    write_last_action_result
	(make_ply_pnick($victim), 'kill', $cause) if(defined($cause));
}

sub do_save {
    my ($cause, $saved) = @_;

    $players{$saved}{'alive'} = 1;
    write_last_action_result
	(make_ply_pnick($saved), 'save', $cause) if(defined($cause));
}

sub do_vote {
    my ($voter, $vote, $vote_weight) = @_;

    # Save the vote
    $players{$voter}{'answered'} = 1;
    $players{$voter}{'vote'} = make_ply_pnick($vote);
    $players{$voter}{'vote_weight'} = $vote_weight ? $vote_weight : 1;
}

# This action is called each time we look at a vote result. It's basically
# called each time someone votes.
# Arg 1 : 1 if vote ends because someone is fully designated
#         0 if the vote issue cannot be established yet
#         if equals votes makes the issues undefined
# Arg 2 : the vote target, if any
# Arg 3,4... : others targets if equals votes
sub do_vote_result {
    our (%votes, %phs);
    my ($vote_issue, @victims) = @_;

    if($vote_issue == 1) { # vote finished, execute the endsub
	if(ref($votes{ $phs{'current'} }{'endsub'}) eq 'CODE') {
	    $votes{ $phs{'current'} }{'endsub'}->(@victims);
	}
	do_next_step();

    } elsif($vote_issue == -1) { # equal votes
	say(P_GAMEADV, 'info', $CFG{ $votes{ $phs{'current'} }{'chan'} },
	    merge_votemsg($messages{'votes'}{'equal_voices'}),
	    join(", ", @victims) );
    }
}

# Helps the subs that needs to check the winning of someone(s), giving
# informations about the numbers of players. Returns this array:
# ( $alive_players_number, $alive_werewolves_number )
sub get_players_stats {
    my @alive_players = alive_players();
    my $num_p = @alive_players;
    my $num_w = 0;

    foreach(@alive_players) {
	$num_w++ if($players{$_}{'job'} eq 'werewolf');
    }
    return ($num_p, $num_w);
}

# do_check_win() sub's sub
sub say_survivors {
    my @alives = alive_players();

    # Add the jobs between parenthesis
    @alives = map { $_ .= ' ('.$messages{'jobs_name'}{ $players{$_}{'job'} }
		    .')' } @alives;

    if(@alives == 1) {
	say(P_GAMEADV, 'info', $CFG{'day_channel'},
	    $messages{'outgame'}{'survivor'}, $alives[0]);
    } else {
	say(P_GAMEADV, 'info', $CFG{'day_channel'},
	    $messages{'outgame'}{'survivors'}, join(', ',@alives));
    }
}

# Check if werewolves, villagers, or nobody wins (no survivors),
# and eventually ends the game.
# Takes one arg: 'end' if we want to make it end the game.
# If it's true and 'end' is the first arg, then it:
# - announces who wins and ends the game
# - makes the last werewolf eat the last villager if needed (this is done here
#   and not in a kill or death_announce hook, because the check_win() action is
#   called only when we _want_ this to be checked, whereas it can be true at
#   others moments but we just want it to be ignored)
# Returns 1 if the game has been ended, 0 otherwise.
sub do_check_win {
    my $end = shift;
    my $do_end = 0;
    my $is_end;
    my ($num_p, $num_w) = get_players_stats();
    my @werewolves; # all the werewolves, alive or dead
    my @alive_players = alive_players();
    my $say = sub_say(P_GAMEADV, 'info', $CFG{'day_channel'});
    $do_end = 1 if(defined($end) && $end eq 'end');

    foreach(keys(%players)) {
	next unless(exists($players{$_}{'job'}));
	next unless(defined($players{$_}{'job'}));
	push(@werewolves, $_) if($players{$_}{'job'} eq 'werewolf');
    }

    $is_end = 1;
    if($num_p == 0) {
	if($do_end) {
	    &$say($messages{'outgame'}{'nobody_wins'});
	}

    } elsif($num_w == 0) {
	if($do_end) {
	    say_survivors();
	    &$say($messages{'outgame'}{'villagers_win'},
		  join(', ',@werewolves));
	}

    } elsif(($num_p - $num_w) <= 1) {
	if($do_end) {
	    # Make the last werewolf eat the last villager
	    foreach(@alive_players) {
		# Actually some alive players may be killed by some action hook
		# (in on of the do_action()), so we also check this [1]
		if($players{$_}{'job'} ne 'werewolf'
		   && $players{$_}{'alive'}) { # [1]
		    if($num_w == 1) {
			&$say($messages{'deads'}{'last_werewolf_kill'}, $_);
		    } else {
			&$say($messages{'deads'}{'last_werewolves_kill'}, $_);
		    }
		    do_action('kill', 'werewolf-day', $_);
		    do_action('death_announce', $_);
		}
	    }
	    &$say($messages{'outgame'}{'werewolves_win'},
		  join(', ',@werewolves));
	}
    } else {
	$is_end = 0; # Nobody wins
    }

    write_last_action_result($is_end, 'check_win');
    return;
}

# Called in the morning, announce the werewolves crime.
# May have "before" or "after" hooks for other deaths.
sub do_morning_death_announce {
    my $killed = read_ply_pnick(read_last_action_result('kill', 'werewolf'));
    return unless(defined($killed));
	
    # Announce it
    say(P_GAMEADV, 'info', $CFG{'day_channel'},
	$messages{'deads'}{'werevolves_kill'}, $killed);
	
    return do_action('death_announce', $killed);
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1
