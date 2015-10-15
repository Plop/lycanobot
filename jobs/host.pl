# host.pl
# Please replace the line 42 of sorcerer.pl
# 'next'	   => 'day'
# with
# 'next'	   => 'host'

use strict;
use warnings;

our (%messages, %special_jobs, %CFG, %players);

add_job('host',
{
	'initsub' => sub {
	my $host = shift;

	# Init our private data
	$$host{'data'}{'hosted'} = undef;
	$$host{'data'}{'werewolf_alive'} = 1;
	$$host{'data'}{'sorcerer_kill'} = 0;
	$$host{'data'}{'dead_msg'} = 0;

	# Add actions hooks
	add_action_hook('death_announce', 'replace', \&on_host_become);
	add_action('become', \&do_become);
	},
	'phases' => {
	'host' => {
		'who'		=> 'host',
		'presub'	 => \&pre_host,
		'next'	   => 'day'
	},
	},
	'commands' => {
	'become' => {
		'subaddr'	=> \&cmd_become,
		'from'	   => 'host',
		'to'		 => 'us',
		'phase'	  => 'host',
		'min_args'   => 1,
		'need_admin' => 0,
		'min_args'   => 1,
		'need_alive' => 0
	}
	}
});


# We know we redefine these subs, that intended
no warnings 'redefine';

sub do_become {
	my $to = shift;
	$special_jobs{'host'}{'data'}{'hosted'} = $to;
	write_last_action_result($special_jobs{'host'}{'data'}{'hosted'}, 'become');
}
sub pre_host {
	my $host = read_ply_pnick($special_jobs{'host'}{'nick'});
	my $werwolves_kill = read_ply_pnick(read_last_action_result('kill', 'werewolf'));
	my $sorcerer_kill = read_ply_pnick(read_last_action_result('kill', 'sorcerer_poison'));
	my $death = 0;
	$special_jobs{'host'}{'data'}{'werewolf_alive'} = 1;

	return 0 if(defined($special_jobs{'host'}{'data'}{'hosted'}));
	if(!$players{$host}{'alive'} && !$special_jobs{'host'}{'data'}{'dead_msg'}) {
		say(P_GAMEADV, 'info', $host,
			$messages{'jobs'}{'host'}{'your_death'});
		$special_jobs{'host'}{'data'}{'dead_msg'}=1;
		return 0;
	}

	return 0 if(!$players{$host}{'alive'});
	# is alive or just killed by the werewolves ?
	return 0 if($host ne $werwolves_kill
		&& !$players{$host}{'alive'});
	return 0 if($special_jobs{'host'}{'data'}{'hosted'});

	unless($players{$werwolves_kill}{'alive'}) {
		$special_jobs{'host'}{'data'}{'werewolf_alive'} = 0;
		$death++;
	}
	if(defined($sorcerer_kill)) {
		$special_jobs{'host'}{'data'}{'sorcerer_kill'} = 1;
		$death++;
	}
		
	if($death <= 0) {
		say(P_GAMEADV,'info', $host,
			$messages{'jobs'}{'host'}{'no_deaths'});
		return 0;
	}
	
	my $deaths = undef;
	my $nbdeath = undef;
	$nbdeath = 1;
	unless($special_jobs{'host'}{'data'}{'werewolf_alive'}) {
		$deaths = $CFG{'message'}{'info'}{'prefix'} . $nbdeath++ . ' - ' . $werwolves_kill . ' ' . $messages{'jobs'}{'host'}{'werewolf_kill'};
	}
	if(defined($sorcerer_kill)) {
		$deaths .= "\n" . $CFG{'message'}{'info'}{'prefix'} . $nbdeath++ . ' - ' . $sorcerer_kill . ' ' . $messages{'jobs'}{'host'}{'sorcerer_kill'};
	}
	$deaths =~ s/^\s//;
	
	ask_for_cmd($host, $host, 'become');
	say(P_GAMEADV,'query', $host,
		$messages{'jobs'}{'host'}{'become_intro2'}, $deaths);
	my $remaining_jobs = '';
	foreach(alive_players()) {
		if(($players{$_}{'job'} ne 'werewolf') && ($players{$_}{'job'} ne 'villager') && ($players{$_}{'job'} ne 'host')) {
			$remaining_jobs .= $messages{'jobs_name'}{$players{$_}{'job'}}.', ';
		}
	}
	if(($players{$werwolves_kill}{'job'} ne 'werewolf') && ($players{$werwolves_kill}{'job'} ne 'villager') && ($players{$werwolves_kill}{'job'} ne 'host') && (!$players{$werwolves_kill}{'alive'})) {
		$remaining_jobs .= $messages{'jobs_name'}{$players{$werwolves_kill}{'job'}}.', ';
	}
	if(($players{$sorcerer_kill}{'job'} ne 'werewolf') && ($players{$sorcerer_kill}{'job'} ne 'villager') && ($players{$sorcerer_kill}{'job'} ne 'host') && (!$players{$sorcerer_kill}{'alive'})) {
		$remaining_jobs .= $messages{'jobs_name'}{$players{$sorcerer_kill}{'job'}}.', ';
	}
	
	$remaining_jobs =~ s/, $//;
	if($remaining_jobs ne '') {
		say(P_GAMEADV, 'info', $host,
			$messages{'jobs'}{'host'}{'remaining_jobs'}, $remaining_jobs);
	} else {
		say(P_GAMEADV, 'info', $host,
			$messages{'jobs'}{'host'}{'no_remaining_jobs'});
	}

	do_next_step();
	return 1;
}

## Actions hooks
sub on_host_become {
	my $dead = shift;
	my $becomed = read_last_action_result('become');
	# Debug :
	#say(P_GAMEADV, 'info', $CFG{'day_channel'},
	#	$becomed.' '.$dead);
	return undef unless(defined($becomed) && $dead eq $becomed);

	say(P_GAMEADV, 'info', $CFG{'day_channel'},
		$messages{'jobs'}{'host'}{'hosted'}, $becomed);
	delete_last_action_result('become');

	return 1;
}

## Commands

sub cmd_become {
	my ($ni,$to,$target) = @_;
	my $werwolves_kill = read_ply_pnick(read_last_action_result('kill', 'werewolf'));
	my $sorcerer_kill = read_ply_pnick(read_last_action_result('kill', 'sorcerer_poison'));
	my $targetnick = undef;

	our %last_actions;
	our %players;
	
	if(defined($special_jobs{'host'}{'data'}{'hosted'})) {
		say(P_GAME, 'error',$ni, $messages{'cmds'}{'become'}{'already_become'});
		return 1;
	}
	
	if(((($target eq '2') && ($special_jobs{'host'}{'data'}{'sorcerer_kill'})) || (($special_jobs{'host'}{'data'}{'werewolf_alive'}) && ($target eq '1')))) {
		$targetnick = $sorcerer_kill;
	}
	elsif($target eq 'no') {
		say(P_GAME, 'info', $ni, $messages{'cmds'}{'become'}{'become_no'});
		do_next_step();
		return 1;
	} elsif(($target eq '1') && (!$special_jobs{'host'}{'data'}{'werewolf_alive'})) {
		$targetnick = $werwolves_kill;
	} else {
		say(P_GAME, 'error', $ni, $messages{'cmds'}{'become'}{'invalid_target'});
		return 1;
	}

	do_action('become', $targetnick);
	say(P_GAMEADV, 'reply', $ni,
		$messages{'cmds'}{'become'}{'you_become'}, $targetnick);
	$players{$ni}{'job'} = $players{$targetnick}{'job'};
	$players{$ni}{'team'} = $players{$targetnick}{'team'};
	if(exists $special_jobs{$players{$targetnick}{'job'}}) {
		$special_jobs{$players{$targetnick}{'job'}}{'nick'} = make_ply_pnick($ni);
	}
	say(P_GAMEADV, 'info', $ni,
		$messages{'cmds'}{'become'}{'your_new_job'},
		$messages{'jobs_name'}{$players{$ni}{'job'}});
	if($players{$targetnick}{'job'} eq 'werewolf') {
		say(P_GAMEADV,'query',$ni,$messages{'outgame'}{'invite_werewolf'}, 
			$CFG{'night_channel'}, $CFG{'night_channel'});
		invite(P_GAMEADV, $ni, $CFG{'night_channel'});
	}
	do_next_step();
	return 1;
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1