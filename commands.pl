# commands.pl
# Copyright (C) 2007,2008  Gilles Bedel
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
##########################
# The commands definitions

our (%CFG, %messages, %special_jobs, %chanusers, %players, %send_queue, %phs,
     $in_game);

# Each one consits of at least an associated subaddr and
# a short description (~ 1 line).
#
# Optionnal other opitons includes :
# params = params showed in the usage command
# example = params showed in the example command
# intro = what to say when we ask a player for this command.
#
# The following ones denies the command execution if not satisfied :
# need_admin(boolean, default no) = only admins can run the command if on
# need_moder(boolean, default no) = only moderators can run the command
# if on. Admins can always run a need_moderator flagged command.
# need_alive(boolean, default no) = only alive players duging a game can run it
# to = To who (can only be the bot (/msg)) or where (a channel) the command is
#      exepted to be launch.
# from = from who the command is exepted to be launch
# phase = in which phase the command is exepted to be launch.
#         can be an array of strings if there are several possibilities, or a
#         simple string only one
# min_args = the minimum number of args the command takes
# game_cmd = (boolean, default yes) if the command must be run by a player
# external = internal setting. Means the command were set from an extern jobs.
#
# 'to' and 'from' keys can be either array of things if there are several
# possibilities, or a simple thing only one. A "thing" can be:
# - a string reference, in which case the nick/channel name must match;
# - a string, in which case it may be:
#   - for 'to'   : either 'us' (bot nick), 'day_channel' or 'night_channel';
#   - for 'from' : a job name (the player who own that job),
#
# Admins commands must be executable in private, bcs they must be accessible
# at any time (even devoiced in a channel)
#
# All the commands must return 1 (other return codes reserved to perl's errors,
# if something went wrong inside the function)
#
# The following keys are first taken from %cmdlist if they exists, and then if
# not, red from %messages with this matching :
# descr   -> $messages{'cmds'}{$cmd}{'descr'}
# params  -> $messages{'cmds'}{$cmd}{'params'}
# example -> $messages{'cmds'}{$cmd}{'example'}
# intro   -> $messages{'cmds'}{$cmd}{'intro'}
# See also cmd_lock_help_keys() to prevent that beheavior.
our %cmdlist = (
  'help'   => {
      'subaddr'    => \&cmd_help,
      'example'    => 'start',
      'game_cmd'   => 0
      },
  'start'  => {
      'subaddr'    => \&cmd_start,
	  'to'         => [ 'day_channel' ],
      'phase'      => 'no_game',
      'game_cmd'   => 0
      },
  'stop'   => {
      'subaddr'    => \&cmd_stop,
      'need_moder' => 1,
      'game_cmd'   => 0
      },
  'settimeout' => {
      'subaddr'    => \&cmd_settimeout,
      'need_moder' => 1,
      'min_args'   => 2,
      'game_cmd'   => 0
      },
  'showtimeouts' => {
      'subaddr'    => \&cmd_showtimeouts,
      'game_cmd'   => 0
      },
  'setcards' => {
      'subaddr'    => \&cmd_setcards,
      'need_moder' => 1,
      'min_args'   => 1,
      'phase'      => [ 'no_game', 'wait_play' ],
      'game_cmd'   => 0
      },
  'showcards' => {
      'subaddr'    => \&cmd_showcards,
      'params'     => '[all] [set] [style]',
      'example'    => [ 'all', 'all set', 'style' ],
      'game_cmd'   => 0
      },
  'showstyle' => {
      'subaddr'    => \&cmd_showstyle,
      'example'    => [ 'classic' ],
      'game_cmd'   => 0
      },
  'tutorial' => {
      'subaddr'    => \&cmd_tutorial,
      'params'     => '[on|off]',
      'example'    => 'off',
      'game_cmd'   => 0
      },
  'vote'   => {
      'subaddr'    => \&cmd_vote,
      'to'         => [ 'day_channel', 'night_channel' ],
      'min_args'   => 1,
      'phase'      => [ ], # autofilled in init_game()
      'need_alive' => 1
      },
  'unvote' => {
      'subaddr'    => \&cmd_unvote,
      'to'         => [ 'day_channel', 'night_channel' ],
      'phase'      => [ ], # autofilled in init_game()
      'need_alive' => 1
      },
  'choose' => {
      'subaddr'    => \&cmd_choose,
      'params'     => '(1|2|no)',
      'example'    => '1',
      'from'       => 'thievish',
      'to'         => 'us', # private msg only
      'min_args'   => 1,
      'phase'      => 'thievish',
      'need_alive' => 1
      },
	
  'play' => {
      'subaddr'    => \&cmd_play,
	  'to'         => [ 'day_channel' ],
      'phase'      => 'wait_play',
      'game_cmd'   => 0  # Allows smarter error messages
      },
  'unplay' => {
      'subaddr'    => \&cmd_unplay,
      'phase'      => 'wait_play',
      'game_cmd'   => 0  # Allows smarter error messages
      },

    'votestatus' => {
      'subaddr'    => \&cmd_votestatus,
      'phase'      => [ ], # autofilled in init_game()
	  'game_cmd'   => 0
    },
    'talkserv' => {
      'subaddr'    => \&cmd_talkserv,
      'min_args'   => 2,
      'need_admin' => 1,
      'game_cmd'   => 0,
      'to'         => 'us' # private msg only
    },
    'reloadconf' => {
      'subaddr'    => \&cmd_reloadconf,
      'need_admin' => 1,
      'game_cmd'   => 0,
      'phase'      => 'no_game'
    },
    'ident' => {
      'subaddr'    => \&cmd_ident,
      'game_cmd'   => 0
    },
    'hlme' => {
      'subaddr'    => \&cmd_hlme,
      'params'     => "[forever|quit|game|never]", # language independent
      'example'    => [ "forever", "quit", "game", "never" ], # this too
      'game_cmd'   => 0
    },
    'activate' => {
      'subaddr'    => \&cmd_activate,
      'need_moder' => 1,
      'game_cmd'   => 0
    },
    'deactivate' => {
      'subaddr'    => \&cmd_deactivate,
      'need_moder' => 1,
      'game_cmd'   => 0
    }
);


###########################
# Functions that are associated with the commands above
# (cmd_*)

sub cmd_help {
    my ($ni,$to,$cmd) = @_;
    my $reply = sub_say(0, 'reply',$ni); # Priority nogame & noadmin

    if(!defined($cmd)) { # command list
	my @cmds = sort(keys(%cmdlist));
	my @admin_cmds;
	my @moder_cmds;
	my @outgame_cmds;
	my $i = 0;
	while($i < $#cmds) {
	    if($cmdlist{$cmds[$i]}{'need_admin'}) {
		push(@admin_cmds, splice(@cmds,$i,1));
	    } elsif($cmdlist{$cmds[$i]}{'need_moder'}) {
		push(@moder_cmds, splice(@cmds,$i,1));
	    } elsif(exists($cmdlist{$cmds[$i]}{'game_cmd'})
		    && !$cmdlist{$cmds[$i]}{'game_cmd'}) {
		push(@outgame_cmds, splice(@cmds,$i,1));
	    } else {
		$i++;
	    }
	}
	
	&$reply($messages{'cmds'}{'help'}{'admin_commands'},
		$CFG{'cmd_prefix'}.join(', '.$CFG{'cmd_prefix'}, @admin_cmds));
	&$reply($messages{'cmds'}{'help'}{'moder_commands'},
		$CFG{'cmd_prefix'}.join(', '.$CFG{'cmd_prefix'}, @moder_cmds));
	&$reply($messages{'cmds'}{'help'}{'game_commands'},
		$CFG{'cmd_prefix'}.join(', '.$CFG{'cmd_prefix'}, @cmds));
	&$reply($messages{'cmds'}{'help'}{'out_game_commands'},
		$CFG{'cmd_prefix'}.join(', '.$CFG{'cmd_prefix'},@outgame_cmds));
	&$reply($messages{'cmds'}{'help'}{'specific'},
		$CFG{'cmd_prefix'});

    } else { # help for a specific command
	my $descr;

	# delete eventual $CFG{'cmd_prefix'}
	$cmd = substr($cmd, length($CFG{'cmd_prefix'})) if($cmd =~ /^\Q$CFG{'cmd_prefix'}/);

	if(!exists($cmdlist{$cmd})) {
	    say(0, 'error', $ni,
		$messages{'errors'}{'unknown_cmd'}, $cmd, $CFG{'cmd_prefix'});
	    return 1;
	}

	if(exists($cmdlist{$cmd}{'descr'})) {
	    $descr = $cmdlist{$cmd}{'descr'};
	} elsif(exists($messages{'cmds'}{$cmd}{'descr'})) {
	    $descr = $messages{'cmds'}{$cmd}{'descr'};
	}

	if(defined($descr) && length($descr)) {
	    &$reply($CFG{'cmd_prefix'}.$cmd." - ".$descr);
	}

	my ($params, $example) = (get_cmd_params($cmd), get_cmd_example($cmd));
	if(length($params)) {
	    &$reply($messages{'cmds'}{'help'}{'usage'},
		    $CFG{'cmd_prefix'}.$cmd.$params);
	}
	if(length($example)) {
	    &$reply($messages{'cmds'}{'helps'}{'show_example'},
		    $CFG{'cmd_prefix'}.$cmd.$example);
	}
    }
    return 1;
}

sub cmd_start {
    my ($launcher, $talkto) = @_;
    my $say = sub_say({ 'prio' => 0, 'to' => $talkto, 'prefix' => $launcher });
    if($in_game) {
	&$say({'type' => 'error'}, $messages{'cmds'}{'start'}{'run_already'});
	return 1;
    }

    unless(exists( $chanusers{$CFG{'night_channel'}}{$CFG{'nick'}} )) {
	if(is_true($CFG{'use_random_night_channel'})) {
	    &$say({'type' => 'info'},
		  $messages{'cmds'}{'start'}{'cannot_join_hidden'},
		  $CFG{'cmd_prefix'});
	    generate_new_night_channel();
	} else {
	    &$say({'type' => 'info'},
		  $messages{'cmds'}{'start'}{'cannot_join'},
		  $CFG{'night_channel'}, $CFG{'cmd_prefix'});
	}
	our $conn->join($CFG{'night_channel'});
	return 1;
    }

    unless($chanusers{$CFG{'day_channel'}}{$CFG{'nick'}}{'op'}
        && $chanusers{$CFG{'night_channel'}}{$CFG{'nick'}}{'op'})
    {
	if(is_true($CFG{'use_random_night_channel'})) {
	    &$say({'type' => 'error'},
		  $messages{'cmds'}{'start'}{'not_op_hidden'},
		  $CFG{'day_channel'});
	    unless($chanusers{$CFG{'night_channel'}}{$CFG{'nick'}}{'op'}) {
		change_night_channel();
	    }
	} else {
	    &$say({'type' => 'error'},
		  $messages{'cmds'}{'start'}{'not_op'},
		  $CFG{'day_channel'}, $CFG{'night_channel'});
	}
	return 1;
    }

    init_player($launcher); # at least this one wants to play
    say(P_GAMEADV, 'reply', $CFG{'day_channel'},
	$messages{'cmds'}{'start'}{'new_game'}, $launcher);
    if($chanusers{$CFG{'day_channel'}}{$launcher}{'op'}) {
       $players{$launcher}{'op'} = 1;
       if($chanusers{$CFG{'day_channel'}}{$CFG{'nick'}}{'op'}) {
           mode(P_GAMEADV, $CFG{'day_channel'}, '-o', $launcher);
       }
    } elsif($chanusers{$CFG{'day_channel'}}{$launcher}{'halfop'}) {
       $players{$launcher}{'halfop'} = 1;
       mode(P_GAMEADV, $CFG{'day_channel'}, '-h', $launcher);
    }
    mode(P_GAMEADV, $CFG{'day_channel'}, '+v', $launcher);
    hl_them(); # HL the ones who wanted that
    do_next_step();
    return 1;
}

sub init_game {
    our %game_sets;

    my ($launcher) = @_;
    my $infos;

    # Wake up everybody, mark all the players as alive
    foreach(keys(%players)) {
	$players{$_}{'alive'} = 1;
    }

    # Then count the alive players
    my $num_players = keys(%players);
    #int(x+0.5) is a round
    my $num_werewolves = int($num_players*$CFG{'werewolves_proportion'} + 0.5);
    my $num_villagers = $num_players - $num_werewolves;


    if($num_werewolves == 0)
    {
	my $min_players = int(1 + 0.5/$CFG{'werewolves_proportion'});
	say(P_GAMEADV, 'error', $CFG{'day_channel'},
	    $messages{'cmds'}{'start'}{'no_werewolves'}, $min_players);
	return 0;
    }

    ## Distribute random jobs (if possible)
    unless( initialize_players($num_werewolves) ) {
	return 0;
    }

    # Autofill the vote commands phases, using %votes
    foreach my $cmd ('vote', 'votestatus', 'unvote') {
	@{ $cmdlist{$cmd}{'phase'} } = ();
	foreach(keys(our %votes)) {
	    push(@{ $cmdlist{$cmd}{'phase'} }, $_);
	}
    }

    # Defaults modes sets here are +mnN for day chan and +mns for night chan
    # n = no external messages
    # N = no nick change
    # m = moderated
    # s = secret channel
    mode_hook(PRIO_ADMIN, 'begin_game');

    # Start the game !
    $in_game = 1;

    # Disable hl'ing of users who wanted that until a game
    foreach(keys(%players)) {
	$infos = get_infos($_);
	if($$infos{'hlme'} eq 'game') {
	    $$infos{'hlme'} = 'never';
	}
    }
    write_user_infos();

    # Beep everybody
    say(P_GAMEADV, 'info', $CFG{'day_channel'},
	$messages{'time_to'}{'play'}, join(', ',keys(%players)));

    # Announce what cards have been set if that's handled by a style
    if($game_sets{'jobs'}{'style'}) {
	my @cards = map { $messages{'jobs_name'}{$_} }
                    grep { $special_jobs{$_}{'wanted'} } keys(%special_jobs);
	if(@cards) {
	    say(P_GAMEADV, 'info', $CFG{'day_channel'},
		$messages{'cmds'}{'showcards'}{'cards_used'},join(', ',@cards));
	} else {
	    say(P_GAMEADV, 'info', $CFG{'day_channel'},
		$messages{'cmds'}{'showcards'}{'no_cards'});
	}
    }

    foreach my $ply (keys(%players)) {
	say(P_GAMEADV, 'info', $ply,
	    $messages{'cmds'}{'start'}{'your_card'},
	    $messages{'jobs_name'}{ $players{$ply}{'job'} });
    }

    foreach my $ply (keys(%players)) {
       	# Say a little help if the user need it and is a special character
	if(&get_infos($ply)->{'tuto_mode'} &&
	   exists($messages{'jobs_help'}{ $players{$ply}{'job'} })) {
	    say(P_GAMEADV, 'info', $ply,
		$messages{'jobs_help'}{ $players{$ply}{'job'} });
	}
    }


    # i = invite only
    # If mode +i is already set, we lock $CFG{'night_channel'} from here,
    # otherwise this will be done in on_mode(), when +i will be set
    unless(mode(P_GAMEADV, $CFG{'night_channel'}, '+i')) {
	purge_night_chan();
    }

    if($num_werewolves == 1) {
	say(P_GAMEADV, 'info', $CFG{'day_channel'},
	    $messages{'cmds'}{'start'}{'num_werewolf'}, $num_players);
    } else {
	say(P_GAMEADV, 'info', $CFG{'day_channel'},
	    $messages{'cmds'}{'start'}{'num_werewolves'},
	    $num_werewolves, $num_players);
    }
    return 1;
}

sub cmd_stop {
    my ($launcher,$talkto) = @_;

    unless($in_game || $phs{'current'} eq 'wait_play') {
	say({'type' => 'error', 'to' => $talkto, 'prefix' => $launcher},
	    $messages{'cmds'}{'stop'}{'already_stop'});
	return 1;
    }

    # delete any queued message
    @{ $send_queue{$_} } = () foreach(%send_queue);

    say(P_GAMEADMIN|PRIO_ADVANCE, 'reply', $CFG{'day_channel'},
	$messages{'cmds'}{'stop'}{'game_stopped'}, $launcher);
    end_game();
    return 1;
}

sub cmd_settimeout {
    our (%phases, %game_sets);
    my ($ni,$talkto,$phase_name,$t) = @_;
    my $phase_key = $phase_name;

    if(exists($phases{$phase_name})) {
	$phase_key = $phase_name;
	if(exists($messages{'phases'}{$phase_key}{'name'})) {
	    $phase_name = $messages{'phases'}{$phase_key}{'name'};
	}
    } else { # Find out its name, may be partly typed
	foreach(keys(%{ $messages{'phases'} })) {
	    next unless(defined($messages{'phases'}{$_}{'name'}));
	    if($messages{'phases'}{$_}{'name'} =~ /\Q$phase_name/i) {
		$phase_key = $_;
		$phase_name = $messages{'phases'}{$_}{'name'};
		last;
	    }
	}
    }

    my $say = sub_say({'prio' => P_ADMIN, 'to' => $talkto, 'type' => 'reply',
		       'prefix' => $ni });
    unless(exists($phases{$phase_key})) {
	&$say({'type' => 'error'},
	    $messages{'errors'}{'unknown_phase'}, $phase_name);
	return 1;
    }

    if($t =~ /^\D/) {
	&$say({'type' => 'error'}, $messages{'errors'}{'not_an_int'}, $t);
	return 1;
    }

    $game_sets{'timeouts'}{$phase_key} = $t;
    write_game_sets();
    &$say({'prefix' => ''},
	  $messages{'cmds'}{'settimeout'}{'timeout_set'}, $phase_name, $t);
    return 1;
}

sub cmd_showtimeouts {
    our %game_sets;
    my ($ni,$talkto) = @_;
    my @tmt;
    my ($phs,$t);

    while( ($phs,$t) = each(%{ $game_sets{'timeouts'} }) ) {
	if(exists($messages{'phases'}{$phs}{'name'})) {
	    push(@tmt, $messages{'phases'}{$phs}{'name'}.": ".$t."s");
	} else {
	    push(@tmt, $phs.": ".$t."s");
	}
    }

    say(0, 'reply', $talkto, $messages{'cmds'}{'showtimeouts'}{'timeouts'},
	join(', ',@tmt));
    return 1;
}

sub cmd_setcards {
    my ($ni,$talkto,$act,$cardname) = @_;
    my $reply = sub_say({'to' => $talkto, 'prio' => P_ADMIN,'type' => 'reply'});
    my $err   = sub_say({'to' => $talkto, 'prio' => P_ADMIN,'type' => 'error',
			 'prefix' => $ni});

    if($act eq 'add' || $act eq 'del') {
	cmd_setcards_card($reply,$err,$act,$cardname)
	    and	write_game_sets();
    } elsif($act eq 'style' || $act eq 'nostyle') {
	cmd_setcards_style($reply,$err,$act,$cardname)
	    and	write_game_sets();
    } else {
	&$err($messages{'cmds'}{'setcards'}{'wrong_act'}, $act);
    }
    return 1;
}

sub cmd_setcards_card {
    our %game_sets;

    my ($reply,$err,$act,$cardname) = @_;
    my $card = $cardname;
    my $style = '';

    unless(defined($cardname)) {
	&$err($messages{'cmds'}{'setcards'}{'need_card'});
	return 0;
    }

    # converts from the language card name to the hash key name, if found
    foreach(keys(%special_jobs)) {
	if($messages{'jobs_name'}{$_} =~ /\Q$cardname/i) {
	    $card = $_;
	    $cardname = $messages{'jobs_name'}{$_};
	    last;
	}
    }

    unless(exists($special_jobs{$card})) {
	&$err($messages{'errors'}{'unknown_card'}, $cardname);
	return 1;
    }

    $style = '_but_style' if($game_sets{'jobs'}{'style'});

    if($act eq 'add') {
	if($game_sets{'jobs'}{'wanted'}{$card}) {
	    &$err($messages{'cmds'}{'setcards'}{'already_set'}, $cardname);
	    return 0;
	}
  
	$game_sets{'jobs'}{'wanted'}{$card} = 1;
	&$reply($messages{'cmds'}{'setcards'}{'card_set'.$style},
		$cardname, $game_sets{'jobs'}{'style'});

    } elsif($act eq 'del') {
	if(!$game_sets{'jobs'}{'wanted'}{$card}) {
	    &$err($messages{'cmds'}{'setcards'}{'already_unset'}, $cardname);
	    return 0;
	}

	$game_sets{'jobs'}{'wanted'}{$card} = 0;
	&$reply($messages{'cmds'}{'setcards'}{'card_unset'.$style},
		$cardname, $game_sets{'jobs'}{'style'});
    }
    return 1;
}

sub cmd_setcards_style {
    our (%game_sets, %games);
    my ($reply,$err,$act,$style) = @_;

    if($act eq 'nostyle') {
	if($game_sets{'jobs'}{'style'}) {
	    $game_sets{'jobs'}{'style'} = '';
	    &$reply($messages{'cmds'}{'setcards'}{'nostyle_set'});
	} else {
	    &$err($messages{'cmds'}{'setcards'}{'already_nostyle'});
	    return 0;
	}
    } elsif($act eq 'style') {
	unless(defined($style)) {
	    &$err($messages{'cmds'}{'setcards'}{'need_style'});
	    return 0;
	}

	if(exists($games{'jobs'}{$style})) {
	    $game_sets{'jobs'}{'style'} = $style;
	    &$reply($messages{'cmds'}{'setcards'}{'style'}, $style);
	} else {
	    &$err($messages{'cmds'}{'setcards'}{'no_such_style'}, $style);
	    return 0;
	}
    }
    return 1;
}

sub cmd_showcards {
    our (%game_sets, $in_game);

    my ($ni,$talkto,@params) = @_;
    my @cards;
    my @ucards;

    my $use_game_sets = 0; # Do we use %game_sets
    my $use_spe_jobs  = 0; # or %special_jobs
    my $style; # If we have to say the used style
    my $set_given   = grep( {$_ eq 'set'  } @params);
    my $style_given = grep( {$_ eq 'style'} @params);

    my $reply = sub_say({'to' => $talkto, 'prio' => 0, 'type' => 'reply'});
    my $err   = sub_say({'to' => $talkto, 'prio' => 0, 'type' => 'error',
			 'prefix' => $ni});
    foreach(@params) {
	unless($_ eq 'set' || $_ eq 'style' || $_ eq 'all') {
	    &$err($messages{'cmds'}{'showcards'}{'wrong_param'}, $_);
	    return 1;
	}
    }

    if($set_given || $style_given) { # Some options given
	if($set_given) {
	    $use_game_sets = 1;
	}
	if($style_given) {
	    $style = $game_sets{'jobs'}{'style'};
	}

    } else { # Default beheaviour
	if($in_game) {
	    $use_spe_jobs  = 1;
	} else {
	    # If we have a style say it
	    if($game_sets{'jobs'}{'style'}) {
		$style = $game_sets{'jobs'}{'style'};
	    } else {
		$use_game_sets = 1;
	    }
	}
    }

    if(defined($style)) {
	if($style) {
	    &$reply($messages{'cmds'}{'showcards'}{'style'}, $style);
	} else {
	    &$reply($messages{'cmds'}{'showcards'}{'nostyle'});
	}
    }

    if($use_game_sets) {
	foreach(keys(%{ $game_sets{'jobs'}{'wanted'} })) {
	    if($game_sets{'jobs'}{'wanted'}{$_}) {
		push(@cards, $messages{'jobs_name'}{$_});
	    } else {
		push(@ucards, $messages{'jobs_name'}{$_});
	    }
	}
    } elsif($use_spe_jobs) {
	foreach(keys(%special_jobs)) {
	    if($special_jobs{$_}{'wanted'}) {
		push(@cards, $messages{'jobs_name'}{$_});
	    } else {
		push(@ucards, $messages{'jobs_name'}{$_});
	    }
	}
    }

    return 1 unless($use_game_sets || $use_spe_jobs);

    if(@cards) {
	if(grep({$_ eq 'set'} @params)) {
	    &$reply($messages{'cmds'}{'showcards'}{'cards_set'},join(', ',@cards));
	} else {
	    &$reply($messages{'cmds'}{'showcards'}{'cards_used'},join(', ',@cards));
	}
    } else {
	&$reply($messages{'cmds'}{'showcards'}{'no_cards'});
    }

    if(grep({$_ eq 'all'} @params)) {
	if(@ucards) {
	    &$reply($messages{'cmds'}{'showcards'}{'cards_unused'},
		    join(', ',@ucards));
	} else {
	    &$reply($messages{'cmds'}{'showcards'}{'all_cards_used'});
	}
    }
    return 1;
}

sub cmd_showstyle {
    our (%games);
    my ($ni,$talkto,$style) = @_;

    my $reply = sub_say({'to' => $talkto, 'prio' => 0, 'type' => 'reply'});
    if(defined($style)) { # Style listing wanted
	unless(exists($games{'jobs'}{$style})) {
	    &$reply({'type' => 'error', 'prefix' => $ni},
		    $messages{'cmds'}{'showstyle'}{'no_such_style'}, $style);
	    return 1;
	}

	# Build the style message
	my $cards = $games{'jobs'}{$style}{'job'};
	my @jobs;
	foreach(keys(%$cards)) {
	    if(exists($cards->{$_}{'num_players'})) {
		push(@jobs, $messages{'jobs_name'}{$_}.': '
		            .$cards->{$_}{'num_players'});
	    } else {
		push(@jobs, $messages{'jobs_name'}{$_}.': '
		            .$messages{'cmds'}{'showstyle'}{'job_always'});
	    }
	}

	if(exists($games{'jobs'}{$style}{'num_players'})) {
	    &$reply($messages{'cmds'}{'showstyle'}{'style_with_ply_limit'},
		    $style, $games{'jobs'}{$style}{'num_players'});
	} else {
	    &$reply($messages{'cmds'}{'showstyle'}{'style'}, $style);
	}
	if(@jobs) {
	    &$reply(join(', ', @jobs));
	} else {
	    &$reply($messages{'cmds'}{'showstyle'}{'no_jobs'});
	}

    } else { # Specific style details
	&$reply($messages{'cmds'}{'showstyle'}{'all_styles'},
		join(', ', keys(%{ $games{'jobs'} })));
    }
    return 1;
}

sub cmd_tutorial {
    my ($ni,$to,$mode) = @_;
    my $infos = get_infos($ni,1);
    my $reply = sub_say({'to' => $to, 'prio' => 0, 'type' => 'reply',
			 'prefix' => $ni});
    # Can't read or store anything without that
    return 1 unless(defined($infos));

    unless(defined $mode) {
	if($infos->{'tuto_mode'}) {
	    &$reply($messages{'cmds'}{'tutorial'}{'tut_is_on'});
	} else {
	    &$reply($messages{'cmds'}{'tutorial'}{'tut_is_off'});
	}
	return 1;
    }
    if($mode eq 'on') {
	if($infos->{'tuto_mode'}) {
	    &$reply({'type' => 'error'},
		    $messages{'cmds'}{'tutorial'}{'tut_already_on'});
	} else {
	    $infos->{'tuto_mode'} = 1;
	    &$reply($messages{'cmds'}{'tutorial'}{'tut_set_on'});
	    write_user_infos(); # Remember that new setting
	}
    } elsif($mode eq 'off') {
	if(!$infos->{'tuto_mode'}) {
	    &$reply({'type' =>'error'},
		     $messages{'cmds'}{'tutorial'}{'tut_already_off'});
	} else {
	    $infos->{'tuto_mode'} = 0;
	    &$reply($messages{'cmds'}{'tutorial'}{'tut_set_off'});
	    write_user_infos(); # Remember that new setting
	}
    } else {
	&$reply({'type' => 'error'},
		$messages{'cmds'}{'tutorial'}{'wrong_param'}, $mode);
    }
    return 1;
}
    
sub cmd_vote {
    our %votes;

    my ($ni,$to,$voted_for_ni) = @_;
    my $num_ply_voted = 0;
    my $num_voters = alive_players(); # by default all the alive players vote
    # Used to find the targetted victim
    my $vote_issue;
    my $victims;
    my $tuto = get_infos($ni)->{'tuto_mode'};
    my $old_vote;
    my $reply = sub_say({'to' => $ni, 'prio' => P_GAMEADV, 'type' => 'reply'});
    my $err   = sub_say({'to' => $to, 'prio' => P_GAME,    'type' => 'error',
			 'prefix' => $ni});

    # Is auth ?
    if(exists($votes{ $phs{'current'} })) {
	unless(lc($to) eq lc($CFG{ $votes{ $phs{'current'} }{'chan'} })) {
	    &$err({'to' => $ni}, $messages{'errors'}{'not_auth'}, "vote");
	    return 1;
	}
    }

    $voted_for_ni = real_nick($ni, $voted_for_ni); # If poorly typed
    $old_vote = read_ply_pnick($players{$ni}{'vote'})
	if(exists($players{$ni}{'vote'}));
    return 1 unless(defined($voted_for_ni)); # More than one player found
    # check if the player exists 
    if(!exists($players{$voted_for_ni})) { # unknown nick
	&$err($messages{'errors'}{'unknown_ply'}, $voted_for_ni);
	return 1;
    }
    # check if he's not dead
    unless($players{$voted_for_ni}{'alive'}) {
	&$err($messages{'errors'}{'dead_ply'}, $voted_for_ni);
	return 1;
    }

    # Also you can't vote against your team if teamvote is not allowed
    if(exists($votes{ $phs{'current'} })
       && !$votes{ $phs{'current'} }{'teamvote'}
       && $players{$ni}{'team'} eq $players{$voted_for_ni}{'team'}) {
	&$err(merge_votemsg($messages{'votes'}{'no_teamvote'}));
	    return 1;
    }

    # Quick and dirty hack: forbid self-votes in day phase
    if($phs{'current'} eq 'day' && $ni eq $voted_for_ni) {
       say(P_GAME, 'error', $ni, "Vous ne pouvez pas voter contre vous-même.");
       return 1;
    }

    # Check if the vote is the same as last one
    if(defined($old_vote) && $old_vote eq $voted_for_ni) {
	&$reply(merge_votemsg($messages{'votes'}{'vote'}),
		$voted_for_ni) if($tuto);
	return 1; # no changes
    }

    # Next do_action() call would change this value, so keep its existence here.

    # Record the vote if the voter is allowed
    return 1 unless(do_action_if_auth('vote', $ni, $voted_for_ni));

    if($tuto) {
	unless(defined($old_vote)) {
	&$reply(merge_votemsg($messages{'votes'}{'vote'}), $voted_for_ni);
	} else {
	&$reply(merge_votemsg($messages{'votes'}{'change_vote'}), 
		$old_vote, $voted_for_ni);
	}
    }

    $vote_issue = check_votes(\$victims);
    do_action('vote_result', $vote_issue,
	      ref($victims) eq 'ARRAY' ? @$victims : $victims);
    return 1;
}

# Helps the cmd_vote sub.
# Takes a $messages{'foo'}{'bar'} as first arg, and returns a ref to an array
# with $messages{'foo'}{'bar'}{'all'} and $messages{'foo'}{'bar'}{the_purpose}
# merged.
sub merge_votemsg {
    our %votes;
    my $msg = shift;
    my $targ = $votes{ $phs{'current'} }{'purpose'};
    my @msgs;
    foreach(('all', $targ)) {
	next unless(exists($$msg{$_}));
	if(ref($$msg{$_}) eq 'ARRAY') {
	    push(@msgs, @{ $$msg{$_} });
	} else {
	    push(@msgs, $$msg{$_});
	}
    }
    return \\@msgs;
}

# Check the voting status
# if the vote issue can be determined (2 possibilities) :
#   absolute majority (not everybody needs to have voted)
#   relative majority (everybody needs to have voted)
# then return 1
# or return 0 if the vote issue cannot be established yet
# or return -1 if equals votes makes the issues undefined
#
# takes 1 arg, a reference on something that depends on the return value :
# if return 1 : the nick of the one the players voted for
# if return 0 : the nick of the player who gets the most voices
#               OR undef if nobody voted
# if return -1 : an array containing the equal players
sub check_votes {
    my $targ_ref = shift;
    my %votes;
    my $num_asw = 0;
    my $num_voters = alive_voters();
    my $total_voices = 0;
    my @targets;
    my $max_score = 0;

    foreach(alive_voters()) {
	my $vote = read_ply_pnick($players{$_}{'vote'});
	$total_voices += $players{$_}{'vote_weight'};
	next if(!exists($players{$_}{'vote'}));
	$num_asw++ if($players{$_}{'answered'});
	unless(exists($votes{$vote})) {
	    $votes{$vote} = 0;
	}

	$votes{$vote} += $players{$_}{'vote_weight'};
    }
    print "-> ".$num_asw." of ".$num_voters." have voted\n";

    foreach(keys(%votes)) {
	if($votes{$_} > $max_score) { # better score
	    $max_score = $votes{$_};
	    @targets = ($_);
	} elsif($votes{$_} == $max_score) { # equal score
	    push(@targets,$_);
	}
    }

    if(@targets > 1) { # more than one target ?
	$$targ_ref = \@targets;
	return -1; # equal vote
    } elsif(@targets == 1) { # exactly one target
	$$targ_ref = $targets[0];
	if($num_asw < $num_voters) { # if not everybody voted
	    if($max_score > $total_voices/2) { # absolute majority
		return 1;
	    }
	} else { # all voted
	    return 1;
	}
    } else { # no votes
	$$targ_ref = undef;
    }
    return 0; # cannot find the vote issue
}

# Cancels a vote
sub cmd_unvote {
    our %votes;
    my ($ni,$to) = @_;
    my $err = sub_say({'to' => $to, 'prio' => P_GAME, 'type' => 'error',
		       'prefix' => $ni});

    # Check if the unvote is given from the right channel
    if(exists($votes{ $phs{'current'} })) {
	unless($to eq $CFG{ $votes{ $phs{'current'} }{'chan'} }) {
	    if(is_true($CFG{'use_random_night_channel'})) {
		&$err({'to' => $ni}, $messages{'errors'}{'wrong_chan_hidden'},
		      'unvote');
	    } else {
		&$err({'to' => $ni}, $messages{'errors'}{'wrong_chan'},
		      'unvote', $CFG{ $votes{ $phs{'current'} }{'chan'} });
	    }
	    return 1;
	}
    }

    unless(exists($players{$ni}{'vote'})) {
	&$err($messages{'cmds'}{'unvote'}{'no_vote'});
	return 1;
    }

    $players{$ni}{'answered'} = 0;
    delete $players{$ni}{'vote'};

    if(get_infos($ni)->{'tuto_mode'}) {
	say(P_GAMEADV, 'reply', $ni,
	    $messages{'cmds'}{'unvote'}{'vote_canceled'});
    }
    return 1;
}

sub cmd_play {
    my ($ni,$to) = @_;
    my $tuto = get_infos($ni)->{'tuto_mode'};
    my $err = sub_say({'to' => $to, 'prio' => P_GAME, 'type' => 'error',
		       'prefix' => $ni});

    # Answer
    if(exists($players{$ni})) {
	&$err( $messages{'cmds'}{'play'}{'already_play'}) if($tuto);
	return 1;
    } else {
	say(P_GAMEADV, 'reply', $ni,
	    $messages{'cmds'}{'play'}{'now_play'}) if($tuto);
    }
    init_player($ni);
    if($chanusers{$CFG{'day_channel'}}{$ni}{'op'}) {
       $players{$ni}{'op'} = 1;
       if($chanusers{$CFG{'day_channel'}}{$CFG{'nick'}}{'op'}) {
           mode(P_GAMEADV, $CFG{'day_channel'}, '-o', $ni);
       }
    } elsif($chanusers{$CFG{'day_channel'}}{$ni}{'halfop'}) {
       $players{$ni}{'halfop'} = 1;
       mode(P_GAMEADV, $CFG{'day_channel'}, '-h', $ni);
       }
    mode(P_GAMEADV, $CFG{'day_channel'}, '+v', $ni); # playing => voice
	say(P_GAMEADMIN, 'info', $CFG{'day_channel'}, 'Attention, il ne reste plus qu\'une place. Le prochain !play déclenchera automatiquement le commencement de la partie.') if(keys(%players)==19);
	do_next_step() if(keys(%players)==20);

    return 1;
}

# Cancels a play request
sub cmd_unplay {
    my ($ni,$to) = @_;

    unless(exists($players{$ni})) {
	say({'prio' => P_GAME, 'type' => 'error', 'to' => $to, 'prefix' => $ni},
	    $messages{'cmds'}{'unplay'}{'no_play'});
	return 1;
    }
    if($players{$ni}{'op'}) {
       if($chanusers{$CFG{'day_channel'}}{$CFG{'nick'}}{'op'}) {
           mode(P_GAMEADV, $CFG{'day_channel'}, '+o', $ni);
       }
    } elsif($players{$ni}{'halfop'}) {
       mode(P_GAMEADV, $CFG{'day_channel'}, '+h', $ni);
    }
    delete $players{$ni};
    mode(P_GAMEADV, $CFG{'day_channel'}, '-v', $ni);

    if(get_infos($ni)->{'tuto_mode'}) {
	say(P_GAMEADV, 'reply', $ni,
	    $messages{'cmds'}{'unplay'}{'play_canceled'});
    }
    return 1;
}

# Prints the vote status : who get how much voices
sub cmd_votestatus {
    our %votes;
    my ($ni,$talkto) = @_;
    my %votestats;
    my @silent_ply;
    my $nb_vote = 0;
    my @msg;
    my $reply = sub_say({'type' => 'reply', 'prio' => P_GAME, 'to' => $talkto});
    # Forbid villagers to run this command if in the werewolves phase
    if($phs{'current'} eq 'werewolf' &&
        ( (exists($players{$ni}) && $players{$ni}{'job'} ne 'werewolf')
	  || !exists($players{$ni}) )
       ) {
	&$reply({'type' => 'error', 'to' => $ni},
		 $messages{'errors'}{'not_auth'}, "votestatus");
	return 1;
    }

    # Count the votes
    foreach(alive_voters()) {
	if(!exists($players{$_}{'vote'})) {
	    push(@silent_ply, $_);
	    next;
	}
	my $vote = read_ply_pnick($players{$_}{'vote'});
	if($players{$_}{'vote_weight'} != 1) {
	    push(@{ $votestats{$vote} },
		 $_.'(x'.$players{$_}{'vote_weight'}.')');
	} else {
	    push(@{ $votestats{$vote} }, $_);
	}
	$nb_vote++;
    }

    # Is anyone voting ?
    if(keys(%votestats) == 0) {
	&$reply(merge_votemsg($messages{'votes'}{'nobody_voted'}));
	return 1;
    }

    # Build the message
    while(my ($for, $who) = each(%votestats)) {
	if(@$who == 1) {
	    push(@msg,
		 parse_msg( merge_votemsg($messages{'votes'}{'status_vote'}),
			    join(',',@$who), $for)
		);
	} else {
	    push(@msg,
		 parse_msg( merge_votemsg($messages{'votes'}{'status_votes'}),
			    join(',',@$who), $for)
		);
	}
    }
    # Say the current votes
    &$reply('['.$nb_vote.'/'.alive_voters().'] ' . join(' - ', @msg));
    # Say who have not voted, if any
    if(@silent_ply == 1) {
	&$reply(merge_votemsg($messages{'votes'}{'silent_player'}),
		$silent_ply[0]);
    } elsif(@silent_ply > 1) {
	&$reply(merge_votemsg($messages{'votes'}{'silent_players'}),
		join(',', @silent_ply));
    }
    return 1;
}

# say something to a service
sub cmd_talkserv {
    my ($ni,$to,$serv,@args) = @_;
    my $nick;

    unless(exists($CFG{'hacks'}{'service'}{$serv})) {
	say({'prio' => P_ADMIN, 'type' => 'error', 'to' => $to,'prefix' => $ni},
	    $messages{'cmds'}{'talkserv'}{'no_such_serv'}, $serv);
	return 1;
    }

    $nick = $CFG{'hacks'}{'service'}{$serv}{'nick'};

    # Is it a good priority choice ? think so...
    say(P_ADMIN, '', $nick, join(' ',@args));
    return 1;
}

sub cmd_reloadconf {
    my ($ni,$to,@cfg) = @_;

    our %files;

    # Config complete path will be said, so keep this private
    my $reply = sub_say({'type' => 'reply', 'prio' => P_ADMIN, 'to' => $ni});
    my $cfg_file;
    if(@cfg) {
	$cfg_file = join(' ', @cfg);
    } else {
	$cfg_file = $files{'cfg'};
    }
    if($cfg_file !~ /^\//) { # Relative path (TODO: windows bastards pathnames)
	$cfg_file = $files{'homedir'}.'/'.$cfg_file;
    }

    if(load_lyca_config_file($cfg_file)) {
	&$reply($messages{'cmds'}{'reloadconf'}{'reloaded'}, $cfg_file);
	ask_who_is($CFG{'day_channel'}); # update_user_infos() for everybody
    } else {
	&$reply({'type' => 'error'},
		$messages{'cmds'}{'reloadconf'}{'error'}, $cfg_file);
    }
    if(@$ ne '') { # Can be only some warnings
	chomp($@);
	my @lines = split("\n", $@);

	# Take the 5 firsts lines
	if(@lines > 5) {
	    splice(@lines, 5);
	    $lines[$#lines+1] = "(...)";
	}
	foreach(@lines) {
	    next unless defined; # Last \n makes an undef line
	    # Take the 120 first chars for each line
	    if(length > 120) {
		s/(.{115}).*$/$1/g; # 115 = 120 - length("(...)")
		$_ .= '(...)';
	    }
	    &$reply({'type' => 'error'}, $_);
	}
    }

    # If the lang has changed in the config file, we must delete all the
    # existing messages and reload the ones in the new language.
    reset_game_vars();

    return 1;
}

# Convert a specified insensitive cased part of a nick,
# to the real nick.
# Return the real nick if found, or the given nick if nobody is found,
# or undef if more than one player is found.
# If more than one player is found, it also prints an error message to $nick
# with a message priority of P_GAME unless $prio is given. Note it's a bad
# idea to say this on a channel, it would annoy people with highlighting.
sub real_nick {
    my ($to, $nick, $prio) = @_;
    my @found;

    $nick =~ s/[^\[\]\\\`\{\|\}\^\-_[:alnum:]]//g;# delete forbidden nick chars
    foreach(keys(%players)) {
	return $_ if(lc_irc($_) eq lc_irc($nick)); # Well spelled
	if(/\Q$nick/i) {
	    push(@found, $_);
	}
    }
    return $nick if(!@found); # Nobody matches

    if(@found > 1) { # Ambigus, more than one match
	say(defined($prio) ? $prio : P_GAME, 'error', $to,
	    $messages{'errors'}{'ambigus_nick'}, $nick, join(", ", @found));
	return undef;
    }
    return $found[0]; # Found !
}

sub cmd_ident {
    our %users; # for admin check
    my ($ni, $to, $target) = @_;

    $target = $ni unless(defined($target));
    my $err = sub_say({'prio' => 0, 'type' => 'error', 'to' => $to,
		       'prefix' => $ni});
    if($target ne $ni && !$users{$ni}{'moder'}) {
	&$err($messages{'cmds'}{'ident'}{'need_moder'});
	return 1;
    }

    unless(exists($users{$target})) {
	# About P_ADMIN: this message must be only for admins. Doing
	# "!ident mynick" should not make this message to be said by a 
	# non-admin wish.
	&$err({'prio' => P_ADMIN}, $messages{'errors'}{'unknown_ply'}, $target);
	return 1;
    }

    ask_who_is($target);
    return 1;
}

sub cmd_hlme {
    my ($ni, $to, $ntil) = @_;
    my $infos = get_infos($ni);

    my $reply = sub_say({'prio' => 0, 'type' => 'reply', 'to' => $to,
			 'prefix' => $ni});
    if(defined($ntil)) {
	if($ntil !~ /^(forever|quit|game|never)$/) {
	    &$reply({'type' => 'error'},
		    $messages{'cmds'}{'hlme'}{'wrong_param'}, $ntil);
	    return 1;
	}

	$$infos{'hlme'} = $ntil;
	write_user_infos(); # Remember that new setting

    } else { # No arg given, asking for state
	$ntil = $$infos{'hlme'};
    }

    &$reply($messages{'cmds'}{'hlme'}{$ntil});
    return 1;
}

sub cmd_activate {
    my ($ni,$to) = @_;
    my $reply = sub_say({'prio' => 0, 'type' => 'reply', 'to' => $to,
			 'prefix' => $ni});

    if(is_true($CFG{'active'})) {
	&$reply($messages{'cmds'}{'activate'}{'already_active'});
    } else {
	$CFG{'active'} = 1;
	&$reply($messages{'cmds'}{'activate'}{'now_active'});
    }
    return 1;
}

sub cmd_deactivate {
    my ($ni,$to) = @_;
    my $reply = sub_say({'prio' => 0, 'type' => 'reply', 'to' => $to,
			 'prefix' => $ni});

    # We MUST be active, otherwise none could have run this command
    if(is_true($CFG{'active'})) {
	$CFG{'active'} = 0;
	&$reply($messages{'cmds'}{'deactivate'}{'now_noactive'});
    }
    return 1;
}

# Protect the command messages from beeing token from others
# %messages messages. Example: "stop" do not take any arg,
# $cmdlist{'stop'}{'params'} do not exists, but someone add a
# $messages{'cmds'}{'stop'}{'params'} string, it would be showed in
# the stop help message. So we add these keys with undef as value.
sub cmd_lock_help_keys {
    my $cmd = shift;

    foreach('descr', 'params', 'example', 'intro') {
	unless(exists($messages{'cmds'}{$cmd}{$_})) {
	    $cmdlist{$cmd}{$_} = undef;
	}
    }
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1
