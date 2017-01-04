# cupid-fr.pl
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

add_job_name_message("cupidon");
add_job_help_message(
[ "Vous possédez la flèche de l'amour qui fera fatalement tomber deux joueurs "
 ."amoureux l'un de l'autre (commande \\cinlove).\n"
 ."Si l'un meurt, l'autre mourra fatalement de chagrin, et ils ne pourront "
 ."pas voter l'un contre l'autre. Vous pouvez être l'un des deux amants." ]
);

add_phase_messages('cupid',
    'name' => "cupidon",
    'timeout' => [ "Temps écoulé ! Vous ne pouvez plus désigner les amoureux." ]
);

add_generic_messages(
'no_vote' => # arg: the player you can't vote for because you are in love with
[ "Vous ne pouvez pas voter contre votre amour.",
  "L'amour que vous portez pour %s vous empêche de faire ça.",
  "Oseriez-vous briser l'amour qui vous lie pour l'éternité à %s ?" ],

'kill' => # arg: the killed player
[ "Et malheureusement, %s est son amant-e, et se suicide "
 ."par chagrin d'amour.",
  "Ainsi que %s, son amour caché, qui préfère se donner la mort "
 ."pour rejoindre l'être aimé.",
  "Mais tels Roméo et Juliette, %s se suicide "
 ."pour être lié, pour l'éternité, à son amour." ],

'amorous_win' => # args: the comma separated amorous
[ "La passion des amoureux %s et %s a été la plus forte.\n"
 ."Ils vivront heureux et auront beaucoup d'enfants (ou pas).",
  "Les amoureux %s et %s ont triomphé.\nLeur passion a dépassé les bas "
 ."instincts des autres villageois et loup-garous." ],
);

add_cmd_messages('inlove',
    'descr'   => "Désigne les amoureux (utilisé par cupidon).",
    'params'  => "<quelqu'un> <quelqu'un d'autre>",
    'example' => [ "adam eve", "tartempion untel" ],
    'intro'   => [ "Cupidon, c'est votre tour !\nDésignez-moi les amoureux.",
		   "A vous de jouer, dites-moi qui sera le couple du jeu.",
		   "C'est à vous, indiquez-moi le nom des amants." ],

    'now_in_love' => # args: the 2 lovers
    [ "Le destin de %s et %s est désormais lié à jamais.",
      "%s et %s ne se sépareront plus jamais.",
      "%s et %s sont fatalement tombés sous leur charme mutuel.",
      "Votre flèche a percé le cœur de %s et %s." ],
    'you_love' =>  # arg: the one the player is in love with
    [ "%s est votre amant-e.",
      "Vous êtes follement tombé-e amoureux-se de %s !",
      "La flèche de cupidon vous fait tomber sous le charme de %s." ],
    'love_suicide' => # arg: the one the player is in love with
    [ "Si vous mourrez, %s mourra inévitablement de chagrin, et inversement.",
      "Si l'un-e d'entre vous meurt, vous mourrez aussi.",
      "Vos vies sont désormais inséparables : le décès de l'une entrainera "
      ."inéluctablement la mort de l'autre." ],
    'cannot_vote' => # arg: the one the player is in love with
    [ "De plus, vous ne pourrez voter contre %s.",
      "Aussi, %s ne pourra être la cible d'un de vos votes." ],
    'same_player' => # arg: the player given twice
    [ "Vous m'avez donné deux fois le même joueur…",
      "Les deux joueurs doivent être différents !",
      "%s ne peut pas être amoureux-se de lui ou d'elle même.",
      "Vous ne m'avez pas dit de qui %s est amoureux-se." ],
    'love_with_werewol' => # arg: the werewolf the player is in love with
    [ "Mais contrairement à vous, %s est un loup-garou.",
      "Mais %s vient d'un monde différent du votre : celui des loup-garous.",
      "Mais derrière le visage envoutant de %s se cache un horrible "
     ."loup-garou !" ],
    'werewol_in_love' => # arg: the player the werewolf is in love with
    [ "Mais contrairement à vous, %s est n'est pas un loup-garou.",
      "Mais %s vient d'un monde différent du votre : "
      ."celui des innocents villageois." ],
    'have_to_win' => 
    [ "Pour gagner, vous et votre amant-e devrez éliminer tous les autres "
      ."joueurs.",
      "L'unique façon de protéger votre amour sera de tuer "
      ."tous les habitants du village." ]
);
