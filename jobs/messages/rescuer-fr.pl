# rescuer-fr.pl
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

add_job_name_message("le salvateur");
add_job_help_message(
[ "Chaque nuit, vous pourrez protéger un joueur à l'aide de "
 ."la commande \\cprotect.\nS'il est la victime des "
 ."loups cette nuit là, il survivra à leur assaut.\nVous "
 ."pouvez vous protégez vous même, et vous ne pouvez pas "
 ."protéger la même personne deux nuits de suite."  ]
);

add_phase_messages('rescuer',
    'name' => "le salvateur",
    'timeout' =>
[ "Temps écoulé ! Personne ne sera protégé cette nuit.",
  "C'est fini ! Hé ben, vous n'êtes pas très solidaire de vos camarades "
 ."villageois !",
  "Temps écoulé… Vous laissez passer une occasion de sauver l'un des vôtres !" ]
);

add_generic_messages(
    'rescue' => # arg: le joueur protégé
    [ "Mais le salvateur a généreusement protégé %s.",
      "Cependant, le salvateur gardait %s sous son aile cette nuit là.",
      "Fort heureusement, le salvateur l'avait protégé.",
      "Mais la protection du salvateur a préservé %s." ]
);

add_cmd_messages('protect',
    'descr'   => "Protège un joueur des attaques des "
                ."loups-garous (utilisé par le salvateur).",
    'intro' => 
    [ "C'est votre tour. Vous pouvez maintenant me désigner quelqu'un que "
     ."vous voulez protéger.",
      "À vous de jouer ! Dites-moi quel est le joueur que vous garderez sous "
     ."votre aile cette nuit.",
      "C'est à vous, faites-moi part du nom de la personne que vous "
     ."souhaitez protéger.",
      "Réveillez-vous ! C'est le moment de me dire qui sera préservé de la "
     ."haine des loups-garous cette nuit.",
      "Hep ! C'est à vous de jouer, qui protégerez-vous ?",
      "Pssst ! Il est temps de me désigner qui sera hors d'atteinte des "
     ."loups-garous cette nuit." ],
    'same_not_twice' => 
    [ "Vous avez déjà protégé %s la nuit dernière.",
      "Vous ne pouvez pas protéger le même personne deux nuits de suite." ],
    'you_protect' => # arg: the just-protected player
    [ "%s est sous votre aile pour cette nuit.",
      "Cette nuit, les loups-garous ne pourrons rien contre %s.",
      "Vous placez temporairement %s hors d'atteinte des loups-garous.",
      "Vous protégez %s d'une éventuelle attaque des loups-garous." ]
);
