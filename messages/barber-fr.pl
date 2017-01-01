# Phrases par pisto

use utf8;
use strict;
use warnings;

add_job_name_message("le barbier");
add_job_help_message(
[ "Vous avez un rasoir qui vous permet d'essayer de tuer quelqu'un d'un coup de rasoir professionnel.\n".
  "Si c'est un loup-garou, il meurt et vous serez pardonné. S'il est innocent, vous mourez avec lui." ]
);

add_generic_messages(
    'barber_fail' =>
    [ "Le barbier vient de tuer un innocent, la vindicte populaire ne se fait pas attendre et le barbier est pendu !"],
    'barber_shave' => 
    [ "%s était en train de se faire servir par le barbier, qui lui a tranché la gorge d'un coup sec."],
	'barber_confiscated' => 
	[ "Les villageois en profitent pour lui confisquer son rasoir." ],
);

add_cmd_messages('shave',
	descr=> "Essayez de tuer quelqu'un d'un coup de rasoir professionnel. Si c'est un loup-garou, il meurt et vous serez pardonné. S'il est innocent, vous mourez avec lui.",
	params => '<victime>',
	used => "Hého, on se calme, toute façon vous n'avez plus de rasoir.",
	no_suicide => 	"Non mais, je sais que la vie est dure, mais c'est pas pour autant qu'il faut se suicider.\n".
					"Essayez plutôt de tuer un loup, ça améliorera les choses."
);

1