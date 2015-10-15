# cacapitaine.pl
# [Autrui@epiknet.org]


use strict;
use warnings;

our (%messages, %CFG, %special_jobs, %players);

add_job('cacapitaine',
{
    'distribute' => 0,
    'initsub' => sub {
	my $captain = shift;

	# Init our private data
	$$captain{'data'}{'gave_to'} = undef;

	# Add here the hook subs
	add_action_hook('death_announce', 'after', \&on_cacapitaine_death);
	add_action_hook('vote',           'after', \&on_cacapitaine_vote);
	add_action_hook('vote_result',    'after', \&on_cacapitaine_vote_eq);

	# Also the give action, so it can be extended
	add_action('give2', \&do_give2);
    },
    'phases' => {
	'cacapitaine' => {
	    'who'        => 'cacapitaine',
	    'presub'     => \&pre_cacapitaine,
	    'postsub'    => \&post_cacapitaine,
	    'next'       => '_begin_round',
	    'timeout_to' => $CFG{'day_channel'}
	},
	'cacapitaine_succession' => {
	    'who'        => 'cacapitaine',
	    'presub'     => \&pre_cacapitaine_succession,
	    'postsub'    => \&post_cacapitaine_succession,
	    'timeoutsub' => \&timeout_cacapitaine_succession,
	    'timeout_to' => $CFG{'day_channel'}
	}
    },
    'votes' => {
	'cacapitaine' => {
	    'chan'     => 'day_channel',
	    'purpose'  => 'for',
	    'teamvote' => 1,
	    'endsub'   => sub {
		write_last_action_result
		    (make_ply_pnick($_[0]), 'elect', 'cacapitaine');
	    }
	}
    },
    'commands' => {
	'give2' => {
	    'subaddr'    => \&cmd_give2,
	    'from'       => 'cacapitaine',
	    'to'         => 'day_channel',
	    'min_args'   => 1,
	    'need_admin' => 0,
	    'need_alive' => 1,
	    'phase'      => 'cacapitaine_succession',
	}
    }
});

# We know we redefine these subs, that intended
no warnings 'redefine';

## Captain phase
sub pre_cacapitaine {
    say(P_GAMEADV, 'query', $CFG{'day_channel'},
	$messages{'jobs'}{'cacapitaine'}{'elect'});
    ask_for_cmd($CFG{'day_channel'}, $CFG{'day_channel'}, 'vote');
    return 1;
}

sub post_cacapitaine {
    my $cap = read_last_action_result('elect', 'cacapitaine');

    # End of villagers'vote, reset them
    foreach(keys(%players)) {
	$players{$_}{'answered'} = 0;
	delete $players{$_}{'vote'};
    }

    $special_jobs{'cacapitaine'}{'nick'} = $cap;
    say(P_GAMEADV, 'info', $CFG{'day_channel'},
	$messages{'jobs'}{'cacapitaine'}{'elected'}, read_ply_pnick($cap));
}

## Captain succession phase
sub pre_cacapitaine_succession {
    my $captain = read_ply_pnick($special_jobs{'cacapitaine'}{'nick'});

    # Devoice everyone in the channel so that the captain speaks alone
    voice_them(P_GAMEADV, $CFG{'day_channel'}, '-');
    say(P_GAMEADV, 'query', $CFG{'day_channel'},
	$messages{'jobs'}{'cacapitaine'}{'succession'}, $captain);

    # Reveal him to let it give
    $players{$captain}{'alive'} = 1;
    ask_for_cmd($captain, $CFG{'day_channel'}, 'give2');
    mode(P_GAMEADV, $CFG{'day_channel'}, '+v', $captain);
    return 1;
}

sub post_cacapitaine_succession {
    my $successor = $special_jobs{'cacapitaine'}{'data'}{'gave_to'};
    my $old_cap = read_ply_pnick($special_jobs{'cacapitaine'}{'nick'});

    say(P_GAMEADV, 'info', $CFG{'day_channel'},
	$messages{'cmds'}{'give2'}{'new_cacapitaine'}, $successor);

    # It should not vote again, but in any case...
    $players{$old_cap}{'vote_weight'} = 1; # Back to default

    # Silently kill the old captain, he has given his last word
    do_kill(undef, $old_cap);
    mode(P_GAMEADV, $CFG{'day_channel'}, '-v', $old_cap); # And devoice him

    $special_jobs{'cacapitaine'}{'nick'} = make_ply_pnick($successor);
    return 1;
}

sub timeout_cacapitaine_succession {
    my $successor = choose_random_player
	(read_ply_pnick($special_jobs{'cacapitaine'}{'nick'}));
    return unless(defined($successor));

    $special_jobs{'cacapitaine'}{'data'}{'gave_to'} = $successor;
    say(P_GAMEADV, 'info', $CFG{'day_channel'},
	$messages{'timeouts'}{'random'}, $successor);
    return 0;
}

## Give command
sub cmd_give2 {
    my ($ni, $to, $target) = @_;

    $target = real_nick($ni, $target); # If poorly typed
    return 1 unless(defined($target)); # More than one player found
    unless(exists($players{$target})) {
	say(P_GAME, 'error', $to,
	    $messages{'errors'}{'unknown_ply'}, $target);
	return 1;
    }
    # forbid to give to any already dead player
    unless($players{$target}{'alive'}) {
	say(P_GAME, 'error', $to,
	    $messages{'errors'}{'dead_ply'}, $target);
	return 1;
    }
    # prevent the captain giving it to itself
    if($target eq $ni) {
	say(P_GAME, 'error', $to,
	    $messages{'cmds'}{'give2'}{'not_yourself'});
	return 1;
    }

    return 1 unless(do_action_if_auth('give2', $target));
    do_next_step();
    return 1;
}

## The give action
sub do_give2 {
    my $to = shift;
    $special_jobs{'cacapitaine'}{'data'}{'gave_to'} = $to;
}

## A good Captain Hook :p
# Everytime someone votes, this sub is lauched. We must know about the captain's
# vote weight right from the beginning of the vote phase. Otherwise, we would
# not be able to well count the votes in check_votes().
sub on_cacapitaine_vote {
    our (%votes, %phs);
    my ($voter, $vote) = @_;
    my $cap = read_ply_pnick($special_jobs{'cacapitaine'}{'nick'});
    return unless(defined($cap) && $players{$cap}{'alive'});

    if($phs{'current'} eq 'day') {
	$players{$cap}{'vote_weight'} = 1;
    } else {
	$players{$cap}{'vote_weight'} = 1;
    }
}

# When the captain is a part of a vote equality, he win the vote
sub on_cacapitaine_vote_eq {
    our (%votes, %phs);
    my ($vote_issue, @voters) = @_;
    my $cap = read_ply_pnick($special_jobs{'cacapitaine'}{'nick'});

    # We want a vote equality, in day phase
    return unless(defined($cap) && $players{$cap}{'alive'}
		  && $vote_issue == -1 && $phs{'current'} eq 'day');

    # Check if everybody voted
    my $n = 0;
    foreach(alive_voters()) {
	if(exists($players{$_}{'vote'})
	   && defined($players{$_}{'vote'})) {
	    $n++;
	}
	$n--;
    }

    if($n == 0) {  # everybody voted
	my $cap_vote = read_ply_pnick($players{$cap}{'vote'});

	my @others = map { $_ ne $cap_vote ? $_ : () } @voters;
	
	if(@voters > @others) { # with captain in the voters
	    say(P_GAMEADV, 'info', $CFG{ $votes{ $phs{'current'} }{'chan'} },
		$messages{'jobs'}{'cacapitaine'}{'concludes_vote'}, $cap);

	    return do_action('vote_result', 1, $cap_vote);
	}
    }
}

sub on_cacapitaine_death {
    my $dead = shift;
    my $captain = read_ply_pnick($special_jobs{'cacapitaine'}{'nick'});

    return unless(defined($captain) && $dead eq $captain
	     &&  $players{$captain}{'connected'} # still here ?
	     && !$players{$captain}{'alive'}); # dead, ready to give ?

    # No need to ask the captain to do something if someone already win
    do_action('check_win');
    return if(read_last_action_result('check_win'));

    return push_phase('cacapitaine_succession');
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1
