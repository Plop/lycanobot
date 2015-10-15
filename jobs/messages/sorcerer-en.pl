# sorcerer-en.pl
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

add_job_name_message("the witch");
add_job_help_message(
    "You have 2 powerful potions: one kills, the other "
    ."resuscitates.\nThey can only be used a single time, "
    ."but at any time I will call you. You would cure the "
    ."werewolves victim (command \\ccure), or poison any player"
    ." (\\cpoison), and then type \\cdone to go back to sleep."
);

add_phase_messages('sorcerer',
    'name' => "the witch",
    'timeout' =>
[ "Timeout reached! Assuming that you did not want to use your potions. "
 ."Please consider using \\cdone to not make me wait for nothing." ]
);

add_generic_messages(
    'werewolves_crime' => # arg: the killed player
    [ "Werewolves have just killed %s!" ],
    'sorcerer_dead' => 
    [ "Werewolves killed you !" ],
    'the_end' => 
    [ "Unfortunaly, it seems that you have already used your curing potion... "
      ."so it's definitely the end." ],
    'kill' => # arg: the killed player
    [ "%s was poisoned by the witch!" ],
    'cure' => # arg: the cured player
    [ "%s was attacked by a pack of hungry werewolves "
      ."but the witch was able to save him." ],
);

add_cmd_messages('cure',
    'descr'   => "Invoke the healing potion. Used by the witch.",
    # intro goes after something like :
    # "Werewolves have just killed <someone> !"
    'intro' => 
    [ "But you can now use your powerful potions!\n"
     ."May you choose to save it or to kill someone else?\nOr the two?!" ],
    'already_cure' => 
    [ "You have already used your healing potion." ],
    'you_cure' => # arg: the just-cured player
    [ "You cured %s - god bless you :)" ],
    'fates_used' => 
    [ "You used your 2 potions, so I will not call you anymore." ]
);

add_cmd_messages('poison',
    'descr'   => "Invoke the poison potion. Used by the witch.",
    'params'  => "<victim>",
    'example' => [ "galiloe" ],
    'you_poison' => # arg: the just-poisonned player
    [ "You poisoned %s." ],
    'already_poison' => 
    [ "You have already used your poison." ],
);

add_cmd_messages('done',
    'descr'   => "Say you have finished using your potions. Used by the witch.",
    'it_s_done' => [ "Okay, good night." ]
);
