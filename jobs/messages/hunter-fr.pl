# hunter-fr.pl
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

add_job_name_message("le chasseur");
add_job_help_message(
[ "Si quelqu'un vous tue, vous aurez le pouvoir de répliquer en tuant "
 ."immédiatemment n'importe quel joueur avant de mourir, avec la commande "
 ."\\chunt." ]
);

add_phase_messages('hunter', 'name' => "le chasseur");

add_cmd_messages('hunt',
    'descr'   => "Réplique en chassant un joueur (utilisé par le chasseur).",
    'params'  => "<joueur ciblé>",
    'example' => [ "Tartempion", "Untel", "Mimamo", "Bliblu", "Villageois" ],
    'intro'   => [ "Le chasseur balaie la foule avec son fusil.\n"
		  ."Il va maintenant tuer un joueur de son choix.",
		   "Il est temps pour le chasseur d'utiliser son fusil, une "
		  ."dernière fois.",
		   "Qui donc la balle du chasseur atteindra-t-elle ?" ],

    'you_hunted' => # arg: the hunted player
    [ "Le chasseur a descendu %s.",
      "PAN ! %s succombe à la balle du chasseur.",
      "La réplique du chasseur est fatale pour %s.",
      "La balle du chasseur traverse la tête de %s.",
      "Le chasseur utilise son ultime balle contre %s." ],
    'no_sucide' =>
    [ "Vous ne pouvez pas vous sucider." ]
);
