# seer-fr.pl
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

add_job_name_message("la voyante");
add_job_help_message(
[ "Chaque nuit, vous pouvez connaître l'identité d'un joueur, "
 ."grâce à la commande \\creveal." ]
);

add_phase_messages('seer',
    'name' => "la voyante",
    'timeout' => 
[ "Le temps dont vous disposiez pour deviner l'identité de d'un joueur s'est "
 ."écoulé !",
  "Ah c'est fini ! Vous avez raté une bonne occasion de démasquer un "
 ."loup-garou.",
  "La lenteur de votre temps de réaction vous a privé de l'opportunité de "
 ."découvrir le vrai visage d'un-e des villageois-es." ]
);

add_cmd_messages('reveal',
    'descr'   => "Révèle l'identité d'un joueur (utilisé par la voyante).",
    'params'  => "<joueur mysterieux>",
    'example' => [ "Tartempion", "Untel", "Mimamo", "Bliblu", "Villageois" ],

    'intro'   =>
[ "C'est votre tour. Vous pouvez maintenant me désigner quelqu'un dont vous "
 ."voulez connaître le vrai visage.",
  "À vous de jouer ! Dites-moi quel est l'inconnu à propos duquel vous "
 ."voulez en savoir plus.",
  "Aha, vous aller maintenant pouvoir connaître l'identité d'un-e "
 ."villageois-e louche.",
  "Pssst ! C'est maintenant ou jamais pour découvrir qui se cache derrière "
 ."ces innocents pseudonymes.",
  "Réveillez-vous ! C'est le moment de me dire quelle est la mysterieuse "
 ."personne sur laquelle vous avez des doutes.",
  "Hep ! C'est à vous de jouer, quel est votre suspect ?" ],

    'who_s_who' => # args: the player, what (s)he is
    [ "%s est %s.", "%s n'est autre que … %s !", "%s est en fait %s." ]
);
