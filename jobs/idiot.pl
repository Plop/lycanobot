# idiot.pl
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

use strict;
use warnings;

our (%messages, %CFG, %special_jobs, %players);

add_job('idiot',
{
    'initsub' => sub {
	my $idiot = shift;

	# Init our private data
	$$idiot{'data'}{'pardoned'} = 0;

	# Add here the hook subs
	add_action_hook('vote_result', 'replace', \&on_idiot_designation);
    }
});

# We know we redefine these subs, that intended
no warnings 'redefine';

## Idiot hooks
# If the idiot is designated by the villagers, he looses his vote and 
sub on_idiot_designation {
    our (%votes, %phs);
    my ($vote_issue, $victim) = @_;
    my $idiot = read_ply_pnick($special_jobs{'idiot'}{'nick'});

    return undef unless($vote_issue == 1 && $victim eq $idiot
	&& $phs{'current'} eq 'day');

    # Idiot must not be pardoned yet
    return undef if($special_jobs{'idiot'}{'data'}{'pardoned'});

    # Deny vote for the idiot
    add_action_auth_rule('vote', 'idiot-vote',
			 { 'phase' => 'day',
			   'args'  => [ make_ply_pnick($idiot) ],
			   'map_args' => \&read_ply_pnick,
			   'failsub' => sub {
			      	say(P_GAME, 'error', $_[0],
				    $messages{'jobs'}{'idiot'}{'no_vote'});
			   }
			 });
    $players{$idiot}{'vote_weight'} = 0; # Do not count him in the votes

    if($special_jobs{'captain'}{'wanted'}) {
	my $cap = read_ply_pnick($special_jobs{'captain'}{'nick'});
	# If he were the captain, there is no more captain in this game
	if($idiot eq $cap) {
	    $special_jobs{'captain'}{'nick'} = undef
	} else {
	    # Also he can't be elected as captain anymore
	    add_action_auth_rule('give', 'idiot-captain',
	       { 'args' => [ make_ply_pnick($idiot) ],
		 'map_args' => \&read_ply_pnick,
		 'failsub' => sub {
		     say(P_GAME, 'error', $cap,
			 $messages{'jobs'}{'idiot'}{'no_give'}, $_[0]);
		 }
	       });
	}
    }

    # We do not call do_action('death_announce') because the idiot is not dead,
    # and therefore we don't want the action hooks to happen.
    announce_death_job($idiot);
    say(P_GAMEADV, 'info', $CFG{'day_channel'},
	$messages{'jobs'}{'idiot'}{'killed'}, $idiot); 

    $special_jobs{'idiot'}{'data'}{'pardoned'} = 1;
    do_next_step();
    return 1; # overstep default vote end
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1
