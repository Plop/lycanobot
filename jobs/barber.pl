use strict;
use warnings;
no warnings 'redefine';

our (%CFG,%players,%messages,%special_jobs);

add_job('barber',{
	'initsub' => sub {
		my $barber=shift;
		$$barber{'data'}{'used'}=0;
	},
	'commands' => {
		'shave'=>{
			'subaddr'    => \&cmd_shave,
			'from'       => 'barber',
			'to'         => 'day_channel',
			'phase'      => 'day',
			'need_admin' => 0,
			'need_alive' => 1
		}
	}
});

sub cmd_shave {
	my ($ni, $to, $victim) = @_;
	my $barber=read_ply_pnick($special_jobs{'barber'}{'nick'});
    my $target = real_nick($ni, $victim);
    return 1 unless(defined($target));
	
	if($special_jobs{'barber'}{'data'}{'used'}) {
		say(P_GAME, 'error', $to, $messages{'cmds'}{'shave'}{'used'});
		return 1;
	}
	
    unless(exists($players{$target})) {
		say(P_GAME, 'error', $ni, $messages{'errors'}{'unknown_ply'}, $target);
		return 1;
    }
	
	if($barber eq $target) {
		say(P_GAME, 'error', $ni, $messages{'cmds'}{'shave'}{'no_suicide'});
		return 1;
	}
	
	say(P_GAMEADV, 'info', $CFG{'day_channel'},	$messages{'jobs'}{'barber'}{'barber_shave'},$target);
	
	$special_jobs{'barber'}{'data'}{'used'}=1;
	
	do_action('kill', undef, $target);
	mode(P_GAMEADV, $CFG{'day_channel'}, '-v', $target);
	do_action('death_announce', $target);
	
	
	if($players{$target}{'job'} eq 'werewolf') {
		say(P_GAMEADV, 'info', $CFG{'day_channel'}, $messages{'jobs'}{'barber'}{'barber_confiscated'});
	}
	else {
		say(P_GAMEADV, 'info', $CFG{'day_channel'}, $messages{'jobs'}{'barber'}{'barber_fail'});
		do_action('kill', undef, $barber);
		mode(P_GAMEADV, $CFG{'day_channel'}, '-v', $barber);
		do_action('death_announce', $barber);
	}
	
	do_action('check_win', 'end');
	if(read_last_action_result('check_win')) {
		do_action('end_game');
	}
	return 1;
}

1