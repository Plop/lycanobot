# seer-en.pl
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

add_job_name_message("the seer");
add_job_help_message(
[ "You have the ability to identify the players identity "
 ."using the \\creveal command." ]
);

add_phase_messages('seer',
    'name' => "the seer",
    'timeout' => [ "Timeout reached! Assuming that you did not want to use "
		   ."your powers." ]
);

add_cmd_messages('reveal',
    'descr'   => "Reveal someone's real identity. Used by the seer.",
    'params'  => "<mysterious player>",
    'example' => [ "foobar" ],

    'intro'   =>
    [ "It's your turn. You can now designate the one "
      ."of which you want to know the real identity",
      "Seer, you play now! Design me a suspicious "
      ."player you want to know more about" ],

    'who_s_who' => # args: the player, what (s)he is
    [ "%s is %s." ]
);
