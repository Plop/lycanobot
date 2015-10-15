# cacapitaine-fr.pl
# [Autrui@epiknet.org]

use utf8;
use strict;
use warnings;

add_job_name_message("le cacapitaine");
#add_job_help_message(); # none, because captain is not distributed

add_phase_messages('cacapitaine', 'name' => "le cacapitaine");

add_generic_messages(
'elected' => # args: the new captain
[ "%s est élu-e cacapitaine du village.",
  "%s est désormais votre maître !",
  "Le nouveau cacapitaine du village est %s." ],

'concludes_vote' => # args: the captain
[ "Le cacapitaine %s tranche le vote dans son sens.",
  "Le cacapitaine %s use de son autorité et conclu le vote en sa faveur.",
  "Qu'importe l'opinion des autres, c'est le cacapitaine %s qui tranche." ],

'elect' =>
[ "Il est temps d'élire le cacapitaine du village.",
  "Il faut commencer par élire le cacapitaine du village.",
  "Mais tout d'abord, votons pour savoir qui sera le cacapitaine du village." ],

'succession' => # args: the dying captain
[ "Le cacapitaine mourrant %s va maintenant choisir son successeur, via la commande !give2.",
  "Tout les villageois sont à l'écoute de %s, qui va dans son dernier souffle "
 ."désigner son successeur, avec la commande !give2.",
  "Émus, les villageois se rassemblent autour de %s, et lui implorent de "
 ."nommer un nouveau cacapitaine, grâce à la commande !give2." ],

);

add_cmd_messages('give2',
    'descr' => "Désigne un-e successeur (utilisé par le cacapitaine).",
    'params' => "<successeur>",
    'example' => [ "Tartempion", "Untel", "Mimamo", "Bliblu", "Villageois" ],
    
    'new_cacapitaine' => # args: the captain successor
    [ "%s est le nouveau cacapitaine du village.",
      "Le nouveau cacapitaine est %s.",
      "Le cacapitaine du village est désormais %s." ],

    'not_yourself' => 
    [ "Vous ne pouvez pas vous succéder à vous-même." ],
);
