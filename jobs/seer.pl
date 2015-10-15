# seer.pl
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

add_job('seer',
{
    'phases' => {
	'seer' => {
	    'who'        => 'seer',
	    'presub'     => \&pre_seer,
	    'next'       => 'rescuer'
	}
    },
    'commands' => {
	'reveal' => {
	    'subaddr'    => \&cmd_reveal,
	    'min_args'   => 1,	       
	    'from'       => 'seer',
	    'to'         => 'us', # private msg only
	    'phase'      => 'seer',
	    'need_admin' => 0,
	    'need_alive' => 1
	}
    }
});

# We know we redefine these subs, that intended
no warnings 'redefine';

## Seer phase
sub pre_seer {
    my $to = read_ply_pnick($special_jobs{'seer'}{'nick'});

    return 0 unless($players{$to}{'alive'} );
    ask_for_cmd($to, $to, 'reveal');
    announce_targs($to, 'alives');
    return 1;
}

## Reveal command
# Used by the seer to reveal him/her a specified user's job
sub cmd_reveal {
    my ($ni,$to,$target) = @_;

    $target = real_nick($ni, $target); # If poorly typed
    return 1 unless(defined($target)); # More than one player found
    unless(exists($players{$target})) {
	say(P_GAME, 'error', $ni, $messages{'errors'}{'unknown_ply'}, $target);
	return 1;
    }

    unless($players{$target}{'alive'}) {
	say(P_GAME, 'error', $ni, $messages{'errors'}{'dead_ply'}, $target);
	return 1;
    }

    say(P_GAMEADV, 'reply',$ni, $messages{'cmds'}{'reveal'}{'who_s_who'},
	$target, $messages{'jobs_name'}{ $players{$target}{'job'} });
    do_next_step();
    return 1;
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1
