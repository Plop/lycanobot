# game_sets.pl
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
##################################
# game settings stuff

our (%special_jobs, %games);

# Current settings for the game, that are synced with settings.xml.
our %game_sets =
(
 'jobs' => {
     'style' => '',
     'wanted' => { # Default special cards, for a fresh lycanobot install
	 'sorcerer' => 1
     }
 },
 'timeouts' => { # Default timeouts, for a fresh lycanobot install
     'wait_play' => 120, 'wait_werewolves' => 120, 'werewolf' => 180,
     'day' => 0, 'captain' => 0, 'captain_succession' => 0,
     'seer' => 60, 'sorcerer' => 60, 'rescuer' => 60,
     'cupid' => 40, 'hunter' => 0,
 }
);

sub write_game_sets {
    return write_persistent_data(\%game_sets, 'game_sets',
				 RootName => 'game_sets',
				 KeyAttr => 0);
}

sub read_game_sets {
    our %files;

    my $data;
    my $filename = $files{'homedir'}.'/'.$files{'game_sets'}{'name'};
    return 1 unless(-e $filename); # Not a fatal error

    $data = read_persistent_data('game_sets', ForceArray => 0, KeyAttr => 0);
    return 0 unless(defined($data));

    # Merge the default conf with the one red
    merge_hash(\\%game_sets, $data);
    print "-> Loaded ".$filename."\n";
    return 1;
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1
