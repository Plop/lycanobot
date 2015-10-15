# sorcerer.pl
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

add_job('sorcerer',
{
    'initsub' => sub {
	my $sorc = shift;

	# Init our private data
	$$sorc{'data'}{'cure_used'} = undef;
	$$sorc{'data'}{'poison_used'} = undef;

	# Add actions hooks
	add_action_hook('death_announce', 'replace', \&on_sorcerer_cure);
	add_action_hook('morning_death_announce','after', \&on_sorcerer_poison);
    },
    'phases' => {
	'sorcerer' => {
	    'who'        => 'sorcerer',
	    'presub'     => \&pre_sorcerer,
	    'next'       => 'host'
	},
    },
    'commands' => {
	'cure' => {
	    'subaddr'    => \&cmd_cure,
	    'from'       => 'sorcerer',
	    'to'         => 'us', # private msg only
	    'phase'      => 'sorcerer',
	    'need_admin' => 0,
	    # Because the sorcerer can cure himself once while dead
	    'need_alive' => 0
	},
	'poison' => {
	    'subaddr'    => \&cmd_poison,
	    'from'       => 'sorcerer',
	    'to'         => 'us', # private msg only
	    'min_args'   => 1,
	    'phase'      => 'sorcerer',
	    'need_admin' => 0,
	    # The sorcerer whould have to cure himself before poisonning anyone
	    'need_alive' => 1
	},
	'done' => {
	    'subaddr'    => \&cmd_done,
	    'from'       => 'sorcerer',
	    'to'         => 'us', # private msg only
	    'phase'      => 'sorcerer',
	    'need_admin' => 0,
	    # Because the sorcerer is called once while being dead
	    'need_alive' => 0
	}
    }
});

# We know we redefine these subs, that intended
no warnings 'redefine';

## Sorcerer phase
sub pre_sorcerer {
    my $sorc = read_ply_pnick($special_jobs{'sorcerer'}{'nick'});# sorcerer nick
    my $werwolves_kill = read_ply_pnick
	(read_last_action_result('kill','werewolf'));

    # is alive or just killed by the werewolves ?
    return 0 if($sorc ne $werwolves_kill
		&& !$players{$sorc}{'alive'});

    # already used his 2 fates ?
    return 0 if($special_jobs{'sorcerer'}{'data'}{'poison_used'}
		&& $special_jobs{'sorcerer'}{'data'}{'cure_used'});

    # Say who was killed
    if($sorc eq $werwolves_kill) {
	say(P_GAMEADV,'info', $sorc,
	    $messages{'jobs'}{'sorcerer'}{'sorcerer_dead'});
    } else {
	say(P_GAMEADV,'info', $sorc,
	    $messages{'jobs'}{'sorcerer'}{'werewolves_crime'}, $werwolves_kill);
    }
	    
    # Can't do anything if sorcerer is dead and his cure was used
    if($sorc eq $werwolves_kill
       && $special_jobs{'sorcerer'}{'data'}{'cure_used'}) {
	say(P_GAMEADV, 'info', $sorc, $messages{'jobs'}{'sorcerer'}{'the_end'});
	return 0; # Go directly to next phase
    } else {
	ask_for_cmd($sorc, $sorc, 'cure', 'poison', 'done');
	# Only announce targs if we can poison
	if(!$special_jobs{'sorcerer'}{'data'}{'poison_used'}) {
	    announce_targs($sorc, 'alives');
	}
    }
    return 1;
}

## Actions hooks
# If the sorcerer cured someone, we don't announce his/her death.
# It's a death_announce replace hook.
sub on_sorcerer_cure {
    my $dead = shift;
    my $sorc_cure = read_ply_pnick(read_last_action_result('save', 'cure'));

    # Did cure happen ?
    return undef unless(defined($sorc_cure) && $dead eq $sorc_cure);

    # Announce cure
    say(P_GAMEADV, 'info', $CFG{'day_channel'},
	$messages{'jobs'}{'sorcerer'}{'cure'}, $sorc_cure);
    delete_last_action_result('save', 'cure'); # cure announced

    return 1; # default death_announce action bypassed
}

# Announces the sorcerer crime.
# An after morning_death_announce hook.
sub on_sorcerer_poison {
    my $poisoned = read_ply_pnick
	(read_last_action_result('kill', 'sorcerer_poison'));

    # Did poison happen ?
    return unless(defined($poisoned));

    # Announce poison
    say(P_GAMEADV, 'info', $CFG{'day_channel'},
	$messages{'jobs'}{'sorcerer'}{'kill'}, $poisoned);

    return do_action('death_announce', $poisoned);
}

## Commands
# Sorcerer fates
sub cmd_poison {
    my ($ni,$to,$target) = @_;

    $target = real_nick($ni, $target); # If poorly typed
    return 1 unless(defined($target)); # More than one player found
    unless(exists($players{$target})) {
	say(P_GAME, 'error', $ni,
	    $messages{'errors'}{'unknown_ply'}, $target);
	return 1;
    }

    if($special_jobs{'sorcerer'}{'data'}{'poison_used'}) {
	say(P_GAME, 'error', $ni,
	    $messages{'cmds'}{'poison'}{'already_poison'} );
	return 1;
    }
    # forbid to kill any already dead player
    unless($players{$target}{'alive'}) {
	say(P_GAME, 'error',$ni, $messages{'errors'}{'dead_ply'}, $target);
	return 1;
    }

    do_action('kill', 'sorcerer_poison', $target);
    $special_jobs{'sorcerer'}{'data'}{'poison_used'} = 1;
    say(P_GAMEADV, 'reply', $ni,
	$messages{'cmds'}{'poison'}{'you_poison'}, $target);

    if($special_jobs{'sorcerer'}{'data'}{'cure_used'}) {
	say(P_GAMEADV, 'info', $ni, $messages{'cmds'}{'cure'}{'fates_used'});
	do_next_step();
	return 1;
    }    
    return 1;
}

sub cmd_cure {
    my ($ni) = @_;
    my $target = read_ply_pnick(read_last_action_result('kill', 'werewolf'));

    # we know if the sorcerer has used his fate bcs of the existence
    # of the key
    if($special_jobs{'sorcerer'}{'data'}{'cure_used'}) {
	say(P_GAME, 'error',$ni, $messages{'cmds'}{'cure'}{'already_cure'});
	return 1;
    }

    do_action('save', 'cure', $target);
    $special_jobs{'sorcerer'}{'data'}{'cure_used'} = 1;
    say(P_GAMEADV, 'reply', $ni,
	$messages{'cmds'}{'cure'}{'you_cure'}, $target);
    
    if($special_jobs{'sorcerer'}{'data'}{'poison_used'}) {
	say(P_GAMEADV, 'info', $ni, $messages{'cmds'}{'cure'}{'fates_used'});
	do_next_step();
	return 1;
    }
    return 1;
}

# Used by the sorcerer to indicate (s)he wants to sleep
sub cmd_done {
    my ($ni) = @_;

    say(P_GAMEADV, 'reply', $ni, $messages{'cmds'}{'done'}{'it_s_done'});
    do_next_step();
    return 1;
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1
