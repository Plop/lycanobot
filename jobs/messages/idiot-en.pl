# idiot-en.pl
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

add_job_name_message("the village idiot");
add_job_help_message(
[ "If the villagers want to kill you, you will be pardoned, but will also "
  ."loose your vote rights, and could not be the captain." ]
);

add_generic_messages(
    'no_vote' => 
    [ "You are the village idiot, so you can't vote." ],
    'killed' => # arg: the idiot
    [ "And the villagers understand his dumb state : %s is pardoned.\n"
     ."Nevertheless, he will not be able neither to vote nor to be the captain." ],
    'no_give' => # arg: the idiot
    [ "%s is the village idiot : you can't give him such status !" ]
);
