# captain-en.pl
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

add_job_name_message("the captain");
#add_job_help_message(); # none, because captain is not distributed

add_phase_messages('captain', 'name' => "the captain");

add_generic_messages(
'elected' => # args: the new captain
[ "%s is elected captain of the village." ],

'concludes_vote' => # args: the captain
[ "The captain %s concludes the vote." ],

'elect' =>
[ "First, let's elect the captain." ],

'succession' => # args: the dying captain
[ "%s is going to designate the new captain." ]
);

add_cmd_messages('give',
    'descr' => "Designate a successor (used by the captain).",
    'params' => "<successor>",
    'example' => [ "foo" ],
    
    'new_captain' => # args: the captain successor
    [ "%s becomes the new village captain." ],

    'not_yourself' => 
    [ "You can't succeed to yourself." ]
);
