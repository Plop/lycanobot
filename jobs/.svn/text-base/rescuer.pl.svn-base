# rescuer.pl
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

add_job('rescuer',
{
    'initsub' => sub {
	my $rescuer = shift;

	# Init our private data
	$$rescuer{'data'}{'protected'} = undef;
	$$rescuer{'data'}{'prev_protected'} = undef;

	# Add actions hooks
	add_action_hook('kill', 'after', \&rescuer_save);
	add_action_hook('death_announce', 'replace', \&on_rescuer_rescue);
	add_action('protect', \&do_protect);
    },
    'phases' => {
	'rescuer' => {
	    'who'        => 'rescuer',
	    'presub'     => \&pre_rescuer,
	    'timeoutsub' => \&timeout_rescuer,
	    'next'       => 'werewolf'
	},
    },
    'commands' => {
	'protect' => {
	    'subaddr'    => \&cmd_protect,
	    'from'       => 'rescuer',
	    'to'         => 'us', # private msg only
	    'phase'      => 'rescuer',
	    'need_admin' => 0,
	    'need_alive' => 1
	}
    }
});

# We know we redefine these subs, that intended
no warnings 'redefine';

## Rescuer phase
sub pre_rescuer {
    my $resc = read_ply_pnick($special_jobs{'rescuer'}{'nick'});
    return 0 unless($players{$resc}{'alive'});

    ask_for_cmd($resc, $resc, 'protect');
    announce_targs($resc, 'alives');
    return 1;
}

sub timeout_rescuer {
    $special_jobs{'rescuer'}{'data'}{'protected'} = undef;
}

## Actions
sub do_protect {
    my $to = shift;
    $special_jobs{'rescuer'}{'data'}{'protected'} = make_ply_pnick($to);
}

## Actions hooks
# After hook for action kill
sub rescuer_save {
    our %phs;
    my ($cause, $target) = @_;
    my $protected = read_ply_pnick($special_jobs{'rescuer'}{'data'}{'protected'});

    # Werewolwes kill context ?
    return unless($cause eq 'werewolf' && $phs{'current'} eq 'werewolf');

    # Save the previous protected player
    $special_jobs{'rescuer'}{'data'}{'prev_protected'}
      = $special_jobs{'rescuer'}{'data'}{'protected'};
    $special_jobs{'rescuer'}{'data'}{'protected'} = undef; # consumed

    # Someone protected ?
    return unless(defined($protected));
    # Which has been attacked by the werewolves ?
    return unless($protected eq $target);

    do_action('save', 'rescuer_rescue', $target);
}

# Replace hook for death_announce if protected
sub on_rescuer_rescue {
    my $dead = shift;
    my $resc = read_ply_pnick(
	read_last_action_result('save', 'rescuer_rescue'));

    # Did rescue happen ?
    return undef unless(defined($resc) && $dead eq $resc);

    # Announce it
    say(P_GAMEADV, 'info', $CFG{'day_channel'},
	$messages{'jobs'}{'rescuer'}{'rescue'}, $resc);
    delete_last_action_result('save', 'rescuer_rescue'); # rescue announced

    return 1; # default death_announce action bypassed
}


## Commands
sub cmd_protect {
    my ($ni,$to,$target) = @_;

    $target = real_nick($ni, $target); # If poorly typed
    return 1 unless(defined($target)); # More than one player found
    unless(exists($players{$target})) {
	say(P_GAME, 'error', $ni,
	    $messages{'errors'}{'unknown_ply'}, $target);
	return 1;
    }

    # Forbid to protect any already dead player
    unless($players{$target}{'alive'}) {
	say(P_GAME, 'error',$ni, $messages{'errors'}{'dead_ply'}, $target);
	return 1;
    }

    # Forbid to protect the same player twice in a row
    if(defined($special_jobs{'rescuer'}{'data'}{'prev_protected'})
       && $target eq read_ply_pnick($special_jobs{'rescuer'}{'data'}{'prev_protected'})) {
	say(P_GAME, 'error', $ni,
	    $messages{'cmds'}{'protect'}{'same_not_twice'}, $target);
	return 1;
    }

    do_action('protect', $target);
    say(P_GAMEADV, 'reply', $ni,
	$messages{'cmds'}{'protect'}{'you_protect'}, $target);

    do_next_step();
    return 1;
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1
