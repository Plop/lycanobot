# sorcerer-fr.pl
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

add_job_name_message("la sorcière");
add_job_help_message(
[ "Vous possédez deux puissantes potions : l'une tue, l'autre "
 ."guérit.\nChacune d'entre elles ne peut être utilisée "
 ."qu'une seule fois, à un des moments où je "
 ."vous appelerai : vous pourrez guérir la victime des loups-garous "
 ."en tapant \\ccure et tuer un joueur avec \\cpoison.\n"
 ."À chaque fois, tapez \\cdone pour m'indiquer que vous avez fini." ]
);

add_phase_messages('sorcerer',
    'name' => "la sorcière",
    'timeout' =>
[ "Temps écoulé ! La prochaine fois tapez \\cdone pour éviter de faire "
 ."attendre les autres joueurs.",
  "C'est fini ! Alors, vous ne vouliez pas utiliser vos potions ? Dans ce cas, "
 ."pensez à taper \\cdone pour ne pas faire attendre tout le monde.",
  "Temps écoulé… Gardez vos puissantes potions pour une autre fois. Pensez "
 ."aussi à taper \\cdone, afin que je ne vous attende pas pour rien." ]
);

add_generic_messages(
    'werewolves_crime' => # arg: the killed player
    [ "Les loups-garous viennent de tuer %s.",
      "Les loups-garous rongent les os de %s.",
      "Les loups-garous viennent de sauvagement dépecer %s." ],
    'sorcerer_dead' => 
    [ "Vous êtes la victime des loups-garous !",
      "Les loups-garous vous ont tué !",
      "Vous passez un sale quart d'heure : c'est vous que les loups-garous "
      ."ont choisi cette nuit." ],
    'the_end' => 
    [ "Or, vous avez déjà utilisé votre potion de guérison, vous ne pouvez "
      ."donc plus rien faire !",
      "Malheureusement, on dirait que vous avez déjà utilisé votre potion de "
      ."guérison, donc c'est vraiment la fin…" ],
    'kill' => # arg: the killed player
    [ "%s a été la victime de la sorcière.",
      "Le poison de la sorcière a tué %s.",
      "La sorcière a empoisonné %s.",
      "%s a succombé au poison de la sorcière." ],
    'cure' => # arg: the cured player
    [ "Mais la sorcière a généreusement guéri %s.",
      "Et la sorcière a gracieusement soigné %s.",
      "Et la sorcière était aux petits soins avec %s, "
      ."qui est de retour parmi nous." ]
);

add_cmd_messages('cure',
    'descr'   => "Utilise la potion de guérison sur la dernière victime des "
                ."loups-garous (utilisé par la sorcière).",
    # intro goes after something like :
    # "Werewolves have just killed <someone> !"
    'intro' => 
    [ "Mais vous pouvez maintenant utiliser (ou pas) vos potions.",
      "Mais peut-être vous auraient-ils contrarié-e sans connaître la "
      ."puissance de vos potions ?",
      "Cependant, vous pouvez changer la donne grâce à vos potions.",
      "Mais, auraient-ils sous-estimé la puissance de vos potions ?" ],
    'already_cure' => 
    [ "Vous avez déjà utilisé votre potion de guérison." ],
    'you_cure' => # arg: the just-cured player
    [ "Vous avez guéri %s.", "Vous avez remis sur pied %s.",
      "%s est à nouveau des notres.", "%s revit !" ],
    'fates_used' => 
    [ "Vous avez utilisé vos deux potions, et donc je ne vous réveillerai "
     ."plus." ]
);

add_cmd_messages('poison',
    'descr'   => "Empoisonne quelqu'un (utilisé par la sorcière).",
    'params'  => "<victime>",
    'example' => [ "Tartempion", "Untel", "Mimamo", "Bliblu", "Villageois" ],
    'you_poison' => # arg: the just-poisonned player
    [ "Vous avez tué %s.", "%s n'est plus.",
      "%s ne fait plus partie du monde des vivants." ],
    'already_poison' => 
    [ "Vous avez déjà utilisé votre potion d'empoisonnement." ]
);

add_cmd_messages('done',
    'descr'   => "Dit que vous avez fini d'utiliser vos potions "
                ."(utilisé par la sorcière).",
    'it_s_done' => 
    [ "Ok, bonne nuit.",
      "Vous vous rendormez comme si de rien n'était.",
      "Nous nous reverrons… ou pas.",
      "Faîtes de beaux rêves." ]
);
