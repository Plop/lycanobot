# rescuer-en.pl
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

add_job_name_message("the rescuer");
add_job_help_message(
[ "Each night, you will be able to protect a player, using "
 ."the \\cprotect command.\nIf he is the werewolves'victim "
 ."this night, he will survive.\nYou can protect yourself, "
 ."and you can't protect the same person twice nights in a row." ]
);

add_phase_messages('rescuer',
    'name' => "the rescuer",
    'timeout' =>
[ "Time's up ! Nobody will be protected this night." ]
);

add_generic_messages(
    'rescue' => # arg: the rescued player
    [ "But the rescuer protected generously protected %s.",
      "However, %s was under the rescuer protection." ]
);

add_cmd_messages('protect',
    'descr'   => "Protect a player from the werewolves attacks "
                ."(used by the rescuer).",
    'intro' => 
    [ "It's your turn. You may now designate me someone you will protect.",
      "You play now! Tell me which player you will take under your "
     ."this night." ],
    'same_not_twice' => 
    [ "You already protected %s last night.",
      "You can't protect the same person twice nights in a row." ],
    'you_protect' => # arg: the just-protected player
    [ "%s is now under your protection.", "You protect %s for this night." ]
);
