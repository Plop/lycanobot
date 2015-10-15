# eldest-fr.pl

# [jolo2@jolo2.eu]



use utf8;

use strict;

use warnings;



add_job_name_message("l'ancien");

add_job_help_message(

[ "Si vous vous faîtes lyncher, vous faites perdre immédiatement les pouvoirs aux villageois.\n"

 ."Les loups-garous vous laissent pour mort, mais grâce à vos capacités de résistance, vous survivez pendant cette nuit à cette attaque." ]

);

add_generic_messages(

    'survive' =>

    [ "Les loups-garous se sont cassé les dents sur une peau plus dure que le chêne.\n".

	  "Il leur faudra revenir achever leur proie une nuit prochaine.",

	  "L'Ancien a été attaqué par les loups, mais sa sagesse et son grand âge lui ont permis de résister à cette attaque.",

	  "Ce n'est pas dans les vieux pots qu'on fait les meilleures soupes et les loups l'ont appris à leur dépens puisque l'Ancien a survécu à leurs crocs !",

	  "Plus fort que Sim et Jeanne Moreau réunis, l'Ancien vit encore et toujours malgré les attaques des loups !",

	  "Les loups sont tombés sur plus malin qu'eux, avec l'Ancien qui a survécu à leur attaque cette nuit.",

	  "L'ancien a l'air bien mal en point ce matin, il lui manque un bout de ventre, mais il marche toujours."] ,

	'designation' => 

	[ "Pour avoir osé attaquer l'ancien, les Dieux vous ont punis et ont ramené ceux d'entre vous aux aptitudes supérieures au rang de pauvres gueux.",

	  "Sacrilège ! Vous avez osé bruler l'ancien, pour cette action hautement répréhensible, je vous enlève vos pouvoirs.",

      "Vous avez brulé l'ancien, et tous vos pouvoirs avec !" ]

);
