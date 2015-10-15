# seer2-fr.pl
# [jolo2@jolo2.eu]

use utf8;
use strict;
use warnings;

add_job_name_message("la voyante bavarde");
add_job_help_message(
[ "Chaque nuit, vous pouvez connaître l'identité d'un joueur, "
 ."grâce à la commande \\creveal2." ]
);

add_phase_messages('seer2',
    'name' => "la voyante bavarde",
    'timeout' => 
[ "Le temps dont vous disposiez pour deviner l'identité de d'un joueur s'est "
 ."écoulé !",
  "Ah c'est fini ! Vous avez raté une bonne occasion de démasquer un "
 ."loup-garou.",
  "La lenteur de votre temps de réaction vous a privé de l'opportunité de "
 ."découvrir le vrai visage d'un-e des villageois-es." ]
);

add_cmd_messages('reveal2',
    'descr'   => "Révèle l'identité d'un joueur (utilisé par la voyante bavarde).",
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
    [ "%s est %s.", "%s n'est autre que … %s !", "%s est en fait %s." ],
	
	'who_w_rea' => # args what she revealed
	[ "Le village est calme cette nuit là ... très calme ...\nSoudain un hurlement retentit ! MAIS TU ES %s !!!!\nEt de nouveau le calme ! D'où venait cette voix ?", "Villageois ! Au milieu de votre nuit, vous ressentez un sentiment confus dans votre esprit...\ncomme si on était en train de vous faire passer un message dans votre sommeil .... et un seul mot revient ... %s"	],
	
	'u_k_who_u_r' => # But but you know who you are.
	[ "Quel est l'intérêt de ceci, vous savez qui vous êtes (Ou schizophrène vous êtes) "]
	
);