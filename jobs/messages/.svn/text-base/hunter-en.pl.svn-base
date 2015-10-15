# hunter-en.pl
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

add_job_name_message("the hunter");
add_job_help_message(
[ "If someone kills you, you can strike back by killing who you want "
 ."before you die, thanks to the \\chunt command" ]
);

add_phase_messages('hunter', 'name' => "the hunter");

add_cmd_messages('hunt',
    'descr'   => "Hunt someone. Used by the hunter.",
    'params'  => "<target>",
    'example' => [ "foo" ],
    'intro'   => [ "The hunter is now going to shoot someone." ],

    'you_hunted' => # arg: the hunted player
    [ "%s was gunned down by the hunter." ],
    'no_sucide' =>
    [ "You can't kill yourself." ]
);
