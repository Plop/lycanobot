
# hunter.pl
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

our (%messages, %CFG, %special_jobs, %players);

add_job('hunter',
{
    'initsub' => sub {
	my $hunter = shift;

	# Init our private data
	$$hunter{'data'}{'hunted'} = undef;

	# Add the hook sub
	add_action_hook('death_announce', 'after', \&on_hunter_death);
    },
    'phases' => {
	'hunter' => {
	    'who'        => 'hunter',
	    'presub'     => \&pre_hunter,
	    'postsub'    => \&post_hunter,
	    'timeoutsub' => \&timeout_hunter,
	    'timeout_to' => $CFG{'day_channel'}
	}
    },
    'commands' => {
	'hunt' => {
	    'subaddr'    => \&cmd_hunt,
	    'from'       => 'hunter',
	    'to'         => 'day_channel',
	    'min_args'   => 1,
	    'need_admin' => 0,
	    'need_alive' => 1,
	    'phase'      => 'hunter',
	}
    }
});

# We know we redefine these subs, that intended
no warnings 'redefine';

## Hunter phase
sub pre_hunter {
    my $prev_phase = shift;
    my $hunter = read_ply_pnick($special_jobs{'hunter'}{'nick'});

    # Devoice everyone in the channel so that the hunter speaks alone
    voice_them(P_GAMEADV, $CFG{'day_channel'}, '-');

    # Reveal him to let it hunt
    $players{$hunter}{'alive'} = 1;
    ask_for_cmd($hunter, $CFG{'day_channel'}, 'hunt');
    mode(P_GAMEADV, $CFG{'day_channel'}, '+v', $hunter);
    return 1;
}

sub post_hunter {
    my $victim = read_ply_pnick($special_jobs{'hunter'}{'hunted'});
    my $hunter = read_ply_pnick($special_jobs{'hunter'}{'nick'});

    say(P_GAMEADV, 'reply', $CFG{'day_channel'},
	$messages{'cmds'}{'hunt'}{'you_hunted'}, $victim);
    do_action('kill', undef, $victim);
    # There is one case we need to devoice the hunter's victim : if hunted
    # in a middle of the day phase phase (not pre or post state), e.g. from
    # a /quit of the hunter's amorous with cupid.
    mode(P_GAMEADV, $CFG{'day_channel'}, '-v', $victim); # So do it.
    do_kill(undef, $hunter); # Silently kill the hunter, he has done his job
    mode(P_GAMEADV, $CFG{'day_channel'}, '-v', $hunter); # And devoice him
    return do_action('death_announce', $victim);
}

sub timeout_hunter {
    my $killed = choose_random_player(
	read_ply_pnick($special_jobs{'hunter'}{'nick'}));
    return unless(defined($killed));

    $special_jobs{'hunter'}{'hunted'} = make_ply_pnick($killed);
    say(P_GAMEADV, 'info', $CFG{'day_channel'},
	$messages{'timeouts'}{'random'}, $killed);
}

## Hunt command
sub cmd_hunt {
    my ($ni, $to, $target) = @_;

    $target = real_nick($ni, $target); # If poorly typed
    return 1 unless(defined($target)); # More than one player found
    unless(exists($players{$target})) {
	say(P_GAME, 'error', $to,
	    $messages{'errors'}{'unknown_ply'}, $target);
	return 1;
    }
    # forbid to kill any already dead player
    unless($players{$target}{'alive'}) {
	say(P_GAME, 'error', $to,
	    $messages{'errors'}{'dead_ply'}, $target);
	return 1;
    }
    # prevent the hunter from commiting sucide
    if($target eq $ni) {
	say(P_GAME, 'error', $to, $messages{'cmds'}{'hunt'}{'no_sucide'});
	return 1;
    }

    $special_jobs{'hunter'}{'hunted'} = $target;
    do_next_step();
    return 1;
}

sub on_hunter_death {
    my $dead = shift;
    my $hunter = read_ply_pnick($special_jobs{'hunter'}{'nick'});

    return unless
      ($dead eq $hunter
       && !defined($special_jobs{'hunter'}{'hunted'}) # undefined hunted yet
       &&  $players{$hunter}{'connected'} # still here ?
       && !$players{$hunter}{'alive'}); # dead, ready to hunt ?

    # No need to ask the hunter to do something if someone already win
    $players{$hunter}{'alive'} = 1; # check_win with the hunter alive
    do_action('check_win');
    $players{$hunter}{'alive'} = 0;
    return if(read_last_action_result('check_win'));

    return push_phase('hunter');
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1
