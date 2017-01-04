# cupid-en.pl
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

use utf8;
use strict;
use warnings;

add_job_name_message("cupid");
add_job_help_message(
[ "You have the power to choose 2 players that will "
 ."desesperatly fall in love together, using the %s"
 ."inlove command.\nIf one die, the other dies too, and "
 ."they cannot vote against each other.\nIf one is a "
 ."werewolf and the other is not, they will have to kill "
 ."all the others players, alone against all." ]
);

add_phase_messages('cupid',
    'name' => "cupid",
    'timeout' => [ "Timeout reached! You can not designate the lovers anymore."]
);

add_generic_messages(
'no_vote' => # arg: the player you can't vote for because you are in love with
[ "You won't vote against your loved %s, want you ?" ],

'kill' => # arg: the killed player
[ "and unfortunately, %s is in love with "
 ."him/her ... (s)he suicides him/herself now... -sniff" ],

'amorous_win' => # args: the comma separated amorous
[ "Amorous (%s and %s) win" ],
);

add_cmd_messages('inlove',
    'descr'   => "Designate the lovers. Used by cupidon.",
    'params'  => "<someone> <anotherone>",
    'example' => [ "foobar barbara" ],
    'intro'   => [ "You play now, choose the lovers!",
		   "Cupidon, it's your turn! Name me the lovers now." ],

    'now_in_love' => # args: the 2 lovers
    [ "%s and %s will be in love ... at least for this game" ],
    'you_love' =>  # arg: the one the player is in love with
    [ "You are in love with %s." ],
    'love_suicide' => # arg: the one the player is in love with
    [ "If %s dies, you will die too, and vice versa." ],
    'cannot_vote' => # arg: the one the player is in love with
    [ "Also, you cannot vote against %s." ],
    'same_player' => # arg: the player given twice
    [ "You specifed %s twice." ],
    'love_with_werewol' => # arg: the werewolf the player is in love with
    [ "But %s comes from a different world than yours : the werewolves one." ],
    'werewol_in_love' => # arg: the player the werewolf is in love with
    [ "But %s is not a werewolf.\n"
     ."Could your love survive with this difference ?" ],
    'have_to_win' => # arg: the player the werewolf is in love with
    [ "You have to win together, killing all the others players." ]
);
