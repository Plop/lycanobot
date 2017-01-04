# captain-fr.pl
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

add_job_name_message("le capitaine");
#add_job_help_message(); # none, because captain is not distributed

add_phase_messages('captain', 'name' => "le capitaine");

add_generic_messages(
'elected' => # args: the new captain
[ "%s est élu-e capitaine du village.",
  "%s est désormais votre maître !",
  "Le nouveau capitaine du village est %s." ],

'concludes_vote' => # args: the captain
[ "Le capitaine %s tranche le vote dans son sens.",
  "Le capitaine %s use de son autorité et conclu le vote en sa faveur.",
  "Qu'importe l'opinion des autres, c'est le capitaine %s qui tranche." ],

'elect' =>
[ "Il est temps d'élire le capitaine du village.",
  "Il faut commencer par élire le capitaine du village.",
  "Mais tout d'abord, votons pour savoir qui sera le capitaine du village." ],

'succession' => # args: the dying captain
[ "Le capitaine mourrant %s va maintenant choisir son successeur.",
  "Tout les villageois sont à l'écoute de %s, qui va dans son dernier souffle "
 ."désigner son successeur.",
  "Émus, les villageois se rassemblent autour de %s, et lui implorent de "
 ."nommer un nouveau capitaine." ],

);

add_cmd_messages('give',
    'descr' => "Désigne un-e successeur (utilisé par le capitaine).",
    'params' => "<successeur>",
    'example' => [ "Tartempion", "Untel", "Mimamo", "Bliblu", "Villageois" ],
    
    'new_captain' => # args: the captain successor
    [ "%s est le nouveau capitaine du village.",
      "Le nouveau capitaine est %s.",
      "Le capitaine du village est désormais %s." ],

    'not_yourself' => 
    [ "Vous ne pouvez pas vous succéder à vous-même." ],
);
