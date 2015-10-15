# host-fr.pl

use utf8;
use strict;
use warnings;

add_job_name_message("l'hôte");
add_job_help_message(
[ "Vous pouvez prendre le rôle d'un mort de la nuit."]
);
add_phase_messages('host',
	'name' => "l'hôte",
	'timeout' =>
[ "Temps écoulé ! Vous ratez l'occasion de devenir l'un des morts." ]
);
add_generic_messages(
	'hosted' =>
	[ "%s est malheuresement mort(e)\n"
	 ."Seulement son âme reste parmi nous grâce à l'hôte.",
	 "%s est mort(e), quel rôle avait-il/elle ? On ne le saura jamais.\n"
	 ."Tout ce que je sais c'est que quelqu'un le réincarne.",
	 "%s n'était rien. Désolé mais je n'ai plus sa carte.\n"
	 ."L'hôte l'a remplacé.",
	 "Mais seulement %s a été réincarné.\n"
	 ."On ne saura jamais son role.\n"
	 ."Mais peut-être est-ce vous qui l'avez réincarné.",
	 "Mais l'esprit de %s règne dans un autre corps." ], 
	'your_death' => # arg: the job of the becomed player
	[ "Vous êtes malheuresement mort, vous ne pouvez plus rien faire.", "C'est malheuresement la fin." ],
	'no_deaths' =>
	[ "Il n'y a pas de morts cette nuit." ],
	'werewolf_kill' => "tué(e) par les loups-garous",
	'sorcerer_kill' => "empoisonné(e) par la sorcière",
	'unknown_kill' => "mort d'une façon mystérieuse",
	'remaining_jobs' => "Il reste comme roles : %s",
	'no_remaining_jobs' => "Il ne reste plus de roles.",
	'become_intro2' =>
	  "%s\n".
	  "Tapez !become <1, 2 ou no>"
);
add_cmd_messages('become',
	'descr'   => "Remplacer une victime de la nuit.",
	'intro' => 
	[ "Bonjour,\n".
	  "Ce matin vous devez choisir si vous voulez remplacer :\n",
	  "J'ai une triste nouvelle à vous annoncer.\n".
	  "Plusieurs de nos villageois sont mort :"],
	'already_become' => 
	[ "Vous avez déjà remplacé quelqu'un." ],
	'you_become' => # arg: the just-becomed player
	[ "Vous êtes devenu %s.", "Vous réincarnez %s." ],
	'your_new_job' => # arg: the job of the becomed player
	[ "Votre role est désormais %s.", "Vous devenez %s." ],
	'invalid_target' => "Argument invalide",
	'become_no' =>
	[ "Vous passez l'occasion de poursuivre l'oeuvre d'une personne.", "OK, vous ne ferez rien cette nuit." ]
);