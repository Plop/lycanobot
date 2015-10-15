# idiot-fr.pl
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

add_job_name_message("l'idiot du village");
add_job_help_message(
[ "Si les villageois vous lynchent, vous serez grâcié, mais perdrez vos droits"
 ." de vote et vous ne pourrez plus être capitaine." ]
);

add_generic_messages(
    'no_vote' => 
    [ "Votre idiotie révélée ne vous permet pas de voter.",
      "Étant connu comme idiot, vous ne pouvez pas participer aux votes." ],
    'killed' => # arg: the idiot
    [ "Et les villageois sont compréhensifs de son état dégénéré : %s est "
     ."grâcié.\nToutefois, il ne pourra plus participer au vote, ni être "
     ."capitaine.",
      "Son air ahuri méprend les villagois : %s est grâcié.\n"
     ."Toutefois, il ne pourra plus participer au vote, ni être capitaine." ],
    'no_give' => # arg: the idiot
    [ "%s est l'idiot du village : vous ne pouvez pas lui confier un tel "
      ."statut !",
      "Oubliriez-vous que %s est l'idiot du village ?" ]
);
