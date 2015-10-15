# cupid.pl
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

our (%messages, %special_jobs, %CFG, %players);

add_job('cupid',
{
    'initsub' => sub {
	my $cupid = shift;

	# Init our private data
	$$cupid{'data'}{'lovers'} = undef;

	# Add here the hook subs
	add_action_hook('death_announce', 'after', \&on_amorous_death);
	add_action_hook('check_win', 'replace', \&on_amorous_win);

	# Vote limitations are dynamically set by cmd_inlove() :)	
    },
    'phases' => {
	'cupid' => {
	    'who'    => 'cupid',
	    'presub' => \&pre_cupid,
	    'next' => 'seer'
	}
    },
    'commands' => {
	'inlove' => {
	    'subaddr'    => \&cmd_inlove,
	    'from'       => 'cupid',
	    'to'         => 'us', # private msg only
	    'min_args'   => 2,
	    'phase'      => 'cupid',
	    'need_admin' => 0,
	    'need_alive' => 1
	}
    }
});

# We know we redefine these subs, that intended
no warnings 'redefine';

## Cupid phase
sub pre_cupid {
    my $to = read_ply_pnick($special_jobs{'cupid'}{'nick'});

    # Only ask cupid in the first round
    return 0 unless(our $round == 1);

    ask_for_cmd($to, $to, 'inlove');
    announce_targs($to, 'alives');
    return 1;
}

## Inlove command
sub cmd_inlove {
    my ($ni,$to,$lover1,$lover2) = @_;
    my $cupid;
    my ($tuto1, $tuto2);
    my $say;

    # Say errors first
    $say = sub_say(P_GAME, 'error', $ni);

    $lover1 = real_nick($ni, $lover1);
    $lover2 = real_nick($ni, $lover2); # If poorly typed
    foreach(($lover1, $lover2)) {
	return 1 unless(defined($_)); # More than one player found
	# check if he's known
	unless(exists($players{$_})) {
	    &$say(\$messages{'errors'}{'unknown_ply'}, $_);
	    return 1;
	}
	# check if he's not dead
	unless($players{$_}{'alive'}) {
	    &$say(\$messages{'errors'}{'dead_ply'}, $_);
	    return 1;
	}
    }

    # Check if it's not the same player
    if($lover1 eq $lover2) {
	&$say(\$messages{'cmds'}{'inlove'}{'same_player'}, $lover1);
	return 1;
    }

    # Say good news then
    $say = sub_say(P_GAMEADV, 'info');

    $tuto1 = get_infos($lover1)->{'tuto_mode'};
    $tuto2 = get_infos($lover2)->{'tuto_mode'};

    $cupid = read_ply_pnick($special_jobs{'cupid'}{'nick'});
    sub say_lover_vote {
	say(P_GAME, 'error', $_[0],
	    \$messages{'jobs'}{'cupid'}{'no_vote'}, $_[1]);
    };
    add_action_auth_rule('vote', 'lovers1',
			 { 'args' => [ make_ply_pnick($lover1),
				       make_ply_pnick($lover2) ],
			   'map_args' => \&read_ply_pnick,
			   'failsub' => \&say_lover_vote
			 });
    add_action_auth_rule('vote', 'lovers2',
			 { 'args' => [ make_ply_pnick($lover2),
				       make_ply_pnick($lover1) ],
			   'map_args' => \&read_ply_pnick,
			   'failsub' => \&say_lover_vote
			 });
    $special_jobs{'cupid'}{'data'}{'lovers'} = [ make_ply_pnick($lover1),
						 make_ply_pnick($lover2) ];

    # Say to each lovers who is their love, only if they are not cupid
    if($lover1 ne $cupid) {
	&$say($lover1, \$messages{'cmds'}{'inlove'}{'you_love'}, $lover2);
	if($tuto1) {
	    &$say($lover1,\$messages{'cmds'}{'inlove'}{'love_suicide'},$lover2);
	    &$say($lover1,\$messages{'cmds'}{'inlove'}{'cannot_vote'}, $lover2);
	}
    }
    if($lover2 ne $cupid) {
	&$say($lover2, \$messages{'cmds'}{'inlove'}{'you_love'}, $lover1);
	if($tuto2) {
	    &$say($lover2,\$messages{'cmds'}{'inlove'}{'love_suicide'},$lover1);
	    &$say($lover2,\$messages{'cmds'}{'inlove'}{'cannot_vote'}, $lover1);
       }
    }

    # Say this at here at the beginning, in case of cupid is one of the lovers,
    # this message would be a replacement for the ones above
    say(P_GAMEADV, 'reply', $ni,
	\$messages{'cmds'}{'inlove'}{'now_in_love'}, $lover1, $lover2);

    # Check if their race is different, in this case they'll have to
    # win together
    if($players{$lover1}{'job'} eq 'werewolf'
       xor $players{$lover2}{'job'} eq 'werewolf') {

	if($players{$lover1}{'job'} eq 'werewolf'
	   && $players{$lover2}{'job'} ne 'werewolf') {
	    &$say($lover2,
		  \$messages{'cmds'}{'inlove'}{'love_with_werewol'}, $lover1);
	    &$say($lover1,
		  \$messages{'cmds'}{'inlove'}{'werewol_in_love'}, $lover2);

	} elsif($players{$lover1}{'job'} ne 'werewolf'
		&& $players{$lover2}{'job'} eq 'werewolf') {
	    &$say($lover1,
		  \$messages{'cmds'}{'inlove'}{'love_with_werewol'}, $lover2);
	    &$say($lover2,
		  \$messages{'cmds'}{'inlove'}{'werewol_in_love'},   $lover1);
	}
	if($tuto1) {
	    &$say($lover1, \$messages{'cmds'}{'inlove'}{'have_to_win'});
	}
	if($tuto2) {
	    &$say($lover2, \$messages{'cmds'}{'inlove'}{'have_to_win'});
	}
    }

    do_next_step();
    return 1;
}

## Hooks
sub on_amorous_death {
    my $dead = shift;

    return 0 unless($special_jobs{'cupid'}{'wanted'});

    # Check for some death due to love
    my $lover = get_lover($dead);
    if(defined($lover) && !$players{$dead}{'alive'}
       && $players{$lover}{'alive'}) {
        say(P_GAMEADV, 'info', $CFG{'day_channel'},
            \$messages{'jobs'}{'cupid'}{'kill'}, $lover);
        do_action('kill', 'cupid', $lover);
        $special_jobs{'cupid'}{'data'}{'lovers'} = undef;
        mode(P_GAMEADV, $CFG{'day_channel'}, '-v', $lover);
        return do_action('death_announce', $lover);
    }
    return 1;
}

# Checks for the lovers win. It's a replace hook.
sub on_amorous_win {
    my $end = shift;
    my $do_end = 1 if(defined($end) && $end eq 'end');
    my $is_end = 0;
    my ($num_p, undef) = get_players_stats();
    my @lovers;

    if(defined($special_jobs{'cupid'}{'data'}{'lovers'}) && $num_p == 2) {
        my @alives = sort(alive_players());
        @lovers = sort(map { read_ply_pnick($_) }
		       @{ $special_jobs{'cupid'}{'data'}{'lovers'} });
        if($alives[0] eq $lovers[0] && $alives[1] eq $lovers[1]
           # have they to win ?
           && ($players{$lovers[0]}{'job'} eq 'werewolf'
           xor $players{$lovers[1]}{'job'} eq 'werewolf') ) {
	    $is_end = 1;
        }
    }

    return undef unless($is_end); # our hook don't replaced the check_win action
    write_last_action_result($is_end, 'check_win');

    if($do_end) {
	# no need to say_survivors() here because survivors are the amorous
	say(P_GAMEADV, 'info', $CFG{'day_channel'},
	    \$messages{'jobs'}{'cupid'}{'amorous_win'}, @lovers);
    }
    return 1; # We oversteped the werewolves/villagers win !
}

# Helper sub
# Return the lover of a given player, or undef if he does not have one
sub get_lover {
    my $who = shift;

    if(defined($special_jobs{'cupid'}{'data'}{'lovers'})) {
        for my $i (0..1) {
            if($who eq read_ply_pnick
	       ($special_jobs{'cupid'}{'data'}{'lovers'}[$i])) {
                return read_ply_pnick
		    ($special_jobs{'cupid'}{'data'}{'lovers'}[1-$i]);
            }
        }
    }
    return undef;
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1
