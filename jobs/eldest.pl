# eldest.pl
# [jolo2@jolo2.eu]

use strict;
use warnings;

our (%messages, %special_jobs, %CFG, %players);

add_job('eldest',
{
    'initsub' => sub {
	my $eldest = shift;

	# Init our private data
	$$eldest{'data'}{'werewolves_killed'} = 0;
	$$eldest{'data'}{'survive_said'} = 0;

	# Add actions hooks
	add_action_hook('kill', 'after', \&eldest_save);
	add_action_hook('save', 'after', \&eldest_cure);
	add_action_hook('death_announce', 'replace', \&on_eldest_survive);
	add_action_hook('vote_result', 'replace', \&on_eldest_designation);
    }
});

# We know we redefine these subs, that intended
no warnings 'redefine';

## Actions hooks
# After hook for action kill
sub eldest_save {
    our %phs;
    my ($cause, $target) = @_;
	return undef if($cause eq undef);
    # Werewolwes kill context ?
    return unless($cause eq 'werewolf' && $phs{'current'} eq 'werewolf');
	return undef unless($target eq read_ply_pnick($special_jobs{'eldest'}{'nick'}));
   
    return if($special_jobs{'eldest'}{'data'}{'werewolves_killed'});
	do_action('save', 'eldest_save', $target);
	$special_jobs{'eldest'}{'data'}{'werewolves_killed'}=1;
	our $dont_say_werewolves_crime = 1;
}

# After hook for action save
sub eldest_cure {
    our %phs;
	my ($cause, $target) = @_;

    return unless(($cause eq 'cure' && $phs{'current'} eq 'sorcerer') || ($cause eq 'rescuer_rescue'  && $phs{'current'} eq 'werewolf'));
	return undef unless($target eq read_ply_pnick($special_jobs{'eldest'}{'nick'}));

	$special_jobs{'eldest'}{'data'}{'werewolves_killed'}=0;
	our $dont_say_werewolves_crime = 0;
	delete_last_action_result('save', 'eldest_save');
	return 1;
}

sub on_eldest_survive {
    my $dead = shift;
	
	return undef unless(defined(read_last_action_result('save', 'eldest_save')));
	return undef unless($dead eq read_ply_pnick($special_jobs{'eldest'}{'nick'}));
    return undef unless(!$special_jobs{'eldest'}{'data'}{'survive_said'});
	
    # Announce it
    say(P_GAMEADV, 'info', $CFG{'day_channel'},
		$messages{'jobs'}{'eldest'}{'survive'});
	$special_jobs{'eldest'}{'data'}{'survive_said'}=1;
	
	delete_last_action_result('save', 'eldest_save');
    return 1;
}

sub on_eldest_designation {
    our (%votes, %phs);
    my ($vote_issue, $victim) = @_;
    my $eldest = read_ply_pnick($special_jobs{'eldest'}{'nick'});
    return undef unless($vote_issue == 1 && $victim eq $eldest
	&& $phs{'current'} eq 'day');
	foreach(keys(%players)) {
		if($players{$_}{'job'} ne 'werewolf' && $players{$_}{'job'} ne 'idiot' && $players{$_}{'job'} ne 'villager' && $players{$_}{'job'} ne 'eldest')	{
			if(exists $special_jobs{$players{$_}{'job'}}) {
				$special_jobs{$players{$_}{'job'}}{'nick'}=undef;
			}
			# $players{$_}{'job'}='villager';
		}
	}
	$special_jobs{'captain'}{'nick'}=undef;

    say(P_GAMEADV, 'info', $CFG{'day_channel'},
		$messages{'jobs'}{'eldest'}{'designation'});

	do_action('kill', undef, $eldest); # villager
	do_action('death_announce', $eldest);
	do_next_step();
	return 1;
}
# The final "1"
# Don't delete it, otherwise including this file will result as an error
1
