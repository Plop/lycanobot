# tban-fr.pl
# Copyright (C) 2010  Gilles Bedel
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

add_cmd_messages('tban',
    'descr' => "Banni et kick un utilisateur ou un masque (utilisé par les modérateurs).",
    'params' => "<temps> <pseudo|masque> [raison]",
    'example' => [ "2j6h lycanobot", "4s3j foobar!*\@example.net" ],
    
    'wrong_time' => 
    [ "Le temps donné '%s' est invalide. Utilisez des combinaisons de <n>[mhjs], par exemple 3j5h." ],
    'unknown_user' =>
    [ "Utilisateur '%s' inconnu. Si c'est un masque, il doit ressembler à *!*\@*." ],
    'need_op' =>
    [ "Je dois être opérateur sur %s pour pouvoir y bannir quelqu'un." ]#,
#    'no_match_mask' =>
#    [ "Le masque '%s' ne correspond à aucun utilisateur sur %s." ]
);
