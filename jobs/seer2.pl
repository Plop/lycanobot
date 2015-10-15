# seer2.pl
# [jolo2@jolo2.eu]

use strict;
use warnings;

our (%messages, %special_jobs, %CFG, %players);

add_job('seer2',
{
    'phases' => {
	'seer2' => {
	    'who'        => 'seer2',
	    'presub'     => \&pre_seer2,
	    'next'       => 'rescuer'
	}
    },
    'commands' => {
	'reveal2' => {
	    'subaddr'    => \&cmd_reveal2,
	    'min_args'   => 1,	       
	    'from'       => 'seer2',
	    'to'         => 'us', # private msg only
	    'phase'      => 'seer2',
	    'need_admin' => 0,
	    'need_alive' => 1
	}
    }
});

# We know we redefine these subs, that intended
no warnings 'redefine';

## seer2 phase
sub pre_seer2 {
    my $to = read_ply_pnick($special_jobs{'seer2'}{'nick'});

    return 0 unless($players{$to}{'alive'} );
    ask_for_cmd($to, $to, 'reveal2');
    announce_targs($to, 'alives');
    return 1;
}

## reveal2 command
# Used by the seer2 to reveal2 him/her a specified user's job
sub cmd_reveal2 {
    my ($ni,$to,$target) = @_;

    $target = real_nick($ni, $target); # If poorly typed
    return 1 unless(defined($target)); # More than one player found
    unless(exists($players{$target})) {
	say(P_GAME, 'error', $ni, $messages{'errors'}{'unknown_ply'}, $target);
	return 1;
    }

	if($target eq $ni) {
		say(P_GAME, 'error', $ni, $messages{'cmds'}{'reveal2'}{'u_k_who_u_r'});
		return 1;
	}
    unless($players{$target}{'alive'}) {
	say(P_GAME, 'error', $ni, $messages{'errors'}{'dead_ply'}, $target);
	return 1;
    }

    say(P_GAMEADV, 'reply',$ni, $messages{'cmds'}{'reveal2'}{'who_s_who'},
	$target, $messages{'jobs_name'}{ $players{$target}{'job'} });
    say(P_GAMEADV, 'info', $CFG{'day_channel'}, $messages{'cmds'}{'reveal2'}{'who_w_rea'},
	$messages{'jobs_name'}{ $players{$target}{'job'} });
    do_next_step();
    return 1;
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1