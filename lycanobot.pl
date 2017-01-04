#!/usr/bin/perl -w

# lycanobot.pl
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


######################################
####### BOT'S CONFIG AND VARS ########
######################################

use strict;

BEGIN {
    # Set our sighandlers asap
    $::run_mode = 1;
    # Restart
    $SIG{HUP} = sub { $::run_mode = 2; };
    # Clean quit
    $SIG{TERM} = sub { $::run_mode = 0; };
    $SIG{INT} = sub { $::run_mode = 0; };

    # Build lycanobot's lib path
    my $basedir = $0;
    if($0 =~ /\//) { # with at least one path
	$basedir =~ s!/[^/]+$!!;
    } else { # cwd
	$basedir = '.';
    }
    unshift(@INC, $basedir.'/libs');
}

use Net::IRC;
use XML::Simple qw(:strict);
use File::Path qw(mkpath);

BEGIN {
    if(eval{require PerlIO::encoding}) {
	# Disable perl's error handling and warnings about unmapped iso chars.
	# This makes perl to ignore errors in print() and decode() when the
	# terminal does not match the encoding and/or a received message
	# couldn't be decoded using the config charset : just do it.
	$PerlIO::encoding::fallback &= ~ (Encode::PERLQQ() | Encode::WARN_ON_ERR());
    }
    if(eval {require I18N::Langinfo}) {
	# Before we print anything, set stdout to the terminal charset
	my $codeset = I18N::Langinfo::langinfo(I18N::Langinfo::CODESET());
	binmode(STDOUT, ":encoding($codeset)");
    } else {
	binmode(STDOUT, ":utf8"); # This is usually good and cannot break things
    }

    use constant LYCA_VERSION => '0.1.2';
    use constant DEFAULT_LANG => 'en';
    print " -- Lycanobot vs. ".LYCA_VERSION." --\n";

    # Use Time::HiRes ' time() func if available,
    # otherwise fall back to perl's builtin one 
    if(eval {require Time::HiRes}) {
	Time::HiRes->import('time');
    } else {
	print "# warning : using 1 second accuracy timers. "
	      ."Install Time::HiRes for a better one\n";
    }

    # A wrapper for Digest::MD5's md5()
    my $have_md5 = eval {require Digest::MD5};
    sub md5 {
	if(defined($have_md5)) {
	    return Digest::MD5::md5(@_);
	} else {
	    return undef;
	}
    }

    # Wrappers for optional Encode module
    my $have_encode = eval {require Encode};
    sub do_decode {
	if(defined($have_encode)) {
	    return Encode::decode($_[0], $_[1], $_[2]);
	} else {
	    return $_[1];
	}
    }
    sub do_encode {
	if(defined($have_encode)) {
	    return Encode::encode($_[0], $_[1], $_[2]);
	} else {
	    return $_[1];
	}
    }

    # UTF-8 to ISO transliteration (such as "…" to "...")
    my $translit;
    if( eval {require Search::Tools::Transliterate} ) {
	$translit = Search::Tools::Transliterate->new();
    }
    sub do_translit {
	if(defined($translit)) {
	    return $translit->convert(chr($_[0]));
	} else {
	    return "?";
	}
    }
}

# Just a sub we need to declare here
# It include a local file or complains on some errors
sub include {
    my ($file) = @_;

    unless (my $return = do $file) {
	die "Couldn't parse $file: $@\n" if $@;
        die "Couldn't do $file: $!\n"    unless defined $return;
        die "Couldn't run $file\n"       unless $return;
    }
}

############################
######## VARIABLES #########
############################

## Game related vars

# These vars need to be initied at every game end in this sub,
# but read those as definitions here.
sub reset_game_vars {
    our $round = 0;      # round number (1 day == 1 round)
    our $in_game = 0;    # Are we currently playing the game ?(0/1)

    # This hash keep the phases and timeout. Keys includes:
    # 'current' is the current phase name. It can be:
    #             thievish, cupid, seer,
    #             werewolf, sorcerer, day, no_game, wait_play, wait_werewolves.
    #           no_game is when no game is running,
    #           wait_play is when someone ran the start command and the bot is
    #           waiting for the players to run the play command
    #           wait_werewolves is when the bot distribute the jobs and then
    #           wait for the werewolves to join the night channel
    # 'state' is the state inside a phase. 'pre' is when are entering the phase,
    #         'post' when we are exiting a phase, and 'in' is between them.
    # 'sub'   is the sub number, if the state involves an array of subs.
    # 'hook'  is the current hook name. May be 'before', 'sub' or 'after'.
    # 'do_action_args' is the args given to the execution of do_action(). It's
    #                  used to go back into the state if a push_phase() occured.
    # 'hook_sub' is the hook sub number, if the hook involes an array of subs.
    # 'stack' keeps the phases state when a phase is cutted by another phase.
    #         It may contain anonymous hashes with the 'current' and 'state'
    #         keys, and also a 'todo' keys that contains a coderef to something
    #         to do when we go back to that push()'ed phase.
    # 'timer' contains undef if no timer is set, or the timer id for the
    #         current phase timeout.
    our %phs;
    remove_timer($phs{'timer'}) if(defined($phs{'timer'}));
    %phs =
	( 'current' => 'no_game',
	  'state'   => 'in', # 'pre', 'post', or 'in',
	  'sub'     => 0,
	  'hooks' => phs_hooks_init(),
	  'stack'   => [ ],
	  'timer' => undef
	);

    # Delete external (and game related) commands
    our %messages; # and its messages
    foreach(keys(our %cmdlist)) {
	if($cmdlist{$_}{'external'}) {
	    delete $cmdlist{$_};
	    delete $messages{'cmds'}{$_};
	}
    }

    # Same for the votes phases
    foreach(keys(our %votes)) {
	if($votes{$_}{'external'}) {
	    delete $votes{$_};
	}
    }

    # Delete external jobs messages
    foreach(keys(our %special_jobs)) {
	delete $messages{'jobs'}{$_};
	delete $messages{'jobs_name'}{$_};
	delete $messages{'jobs_help'}{$_};
    }

    # Delete all the disconnected players'nicks hanging around
    foreach(our @userlist) {
	delete $$_{'lycainfo'}{'game_nick'};
    }

    # Set the basic actions & phases, and clean special jobs, actions and
    # their auth
    load_game_basics(); # from basics.pl

    # Delete external phases messages lying around
    our %phases;
    foreach(keys(%{ $messages{'phases'} })) {
	unless(exists($phases{$_})) {
	    delete $messages{'phases'}{$_};
	}
    }

    # Then load the custom jobs
    our %files;
    load_jobs($files{'basedir'}.'/'.$files{'jobs'});

} # end of reset_game_vars()

# A hash describing the special jobs. The keys are:
# nick       : whose job is assigned to
# help       : a ref to the help message (sent if tutorial mode enabled)
# wanted     : if we want it to be distributed or not
# distribute : optionnal boolan, if the job is distributable or not. Default: 1.
# It also contains extra-informations that are specific for each special job
# (such as 'cure_used', 'poison_used', or 'lovers'). These informations are
# resetted above in reset_game_vars(), whereas the following hash definition
# must be set ONCE, because %cmdlist contains refs to these "nick"s keys.
our %special_jobs;

## Config ##
# All the bot's config is stored here. It will be filled later...
our %CFG;

## Channel modes ##
# One key per channel, and its value is the channel mode
our %chanmode;

## Users database ##
# We use 3 hashes and 1 array :
# %players   is for the game related data. All the informations it contains are
#            ephemeral. Each time a new game start, it's resetted.
# @userlist  is for permanent and private users informations and settings
# %users     is for informations for each user (deleteed if he disconnects)
# %chanusers is for IRC-related informations about each user on a particular
#            channel

# Player list
# It's a hash of hashes with one hash per player,
# which name is the player's nick.
#
# %players's hashes are ephemeral : they are created for each player at the
# beginning of a game, and deleted at the end.
# These hashes contain everything we need to know about a player :
# { 'job'       => werewolf|villager|sorcerer|hunter|cupid|thievish|captain,
#   'team'      => werewolves|villagers,
#   'alive'     => 0|1,
#   'answered'  => 0|1, # if the bot is waiting for all to answer
#   'vote'      => player's vote target nick in portable form,
#   'vote_weight' => player's vote weight
#   'connected' => 0|1 # if the player is disconnect while a game is running,
#                      # his %players entry is deleted when the game finishes.
#   'nick'  => 'joe' # Used to known the nick from a $players{$ni} reference.
#   'deco_timer' => id # Disconnection timer id, if the player is disconnected
# }
our %players = ();

# Users list
# It's an array of anonymous hashes.
#
# This hash is used to keep personnal informations/settings for each user.
# That is, when a user disconnects and then reconnects, if the bot recongnize
# him, he will regain its settings and informations.
# Several connected users can share the same hash, depending on how the bot
# decides a user is a clone of another user. It can do that using one or more
# of the following informations it has about each user (see %ircinfos) :
# nick, user, host, domain, server, realname, regnick
#
# So, each hash has one or more of these keys, plus a 'lycainfo' key, which is
# a hash containing private informations and settings for this user and his
# clones.
# Note that these hashes may be accessed using %ircinfos'private key.
#
# [ { 'nick'     => 'some_nick',           #\
#     'user'     => 'the_user',            # \
#     'host'     => 'some-host',           #  \
#     'domain'   => '.domain.tld',         #   > one or more of these keys
#     'server'   => 'some-irc.server.net', #  /
#     'realname' => 'His Realname',        # /
#     'regnick'  => 'nick'                 #/
#     'lycainfo' => {
#       'tuto_mode' => 1,
#       'last_seen' => 1315491055, # last time we saw this user (in seconds)
#       'game_nick' => 'foo' # The nick the player had in game, if he quits
#     }
#   },
#   { ... }
# ]
our @userlist = ();

# Users informations
# It's a hash of hashes with one hash per channel and user,
# which name is the nick name.
#
# It contains various informations about each user, which are loose when
# he disconnects. It's build like that :
# 'nick' => {
#     'ident' => {  # Infos that can be used to ident users (see @userlist)
#         'user' => 'the_user',
#         'host' => 'some-host',
#         'domain' => '.domain.tld',
#         'server' => 'some-irc.server.net',
#         'realname' => 'His Realname',
#         'regnick'  => 'nick_' # here "nick" is registered as "nick_"
#     },
#     'welcomed' => 1, # yes, this one must not be in @userhost: it's only used
#                        to differenciate users that are already here from the
#                        ones who join the channel.
#     'away' => 1,
#     'admin' => 0,
#     'moder' => 0,
#     'private' => $userhost[n] // ref to his @userlist hash entry
#     'nick'  => 'joe' # Used to known the nick from a $users{$ni} reference.
# },
# 'another_nick' => { ... }
our %users = ();

# Chan users
# This hash contain 2 hashes : the 2 channels the bot
# is connected to (the day channel name and the night channel name).
# Each channel hash contains one hash per user.
# And these users hashes are made up of IRC-related informations :
# voiced, op
our %chanusers = ();

# Where to get our stuff
our %files =
    ( 'basedir' => undef, # where to get others .pl files
      'homedir' => ($ENV{HOME} ||
		    $ENV{USERPROFILE} ||
                    '.').'/.lycanobot', # where to get the config
      'jobs'    => 'jobs', # jobs dir (relative to basedir)
      'cfg'     => undef, # config file name with its path
      'games'   => 'games.xml', # games infos file name (without its path)
      'users' => {
	  'name'  => 'users.dat', # users infos file name (without its path)
	  'md5'   => undef # hash for caching system
      },
      'game_sets' => {
	  'name'  => 'settings.xml', # game current opts (without its path)
	  'md5'   => undef # hash for caching system
      },
      'sync_timer' => undef # timer id for the files synchronization
    );

# There is also $::run_mode that is defined in the first BEGIN block, above.
# It's used by sighandlers to tell what we have to do in the main loop.
# Values: 0: stop, 1: normal run, 2: restart
#$::run_mode = 1

# Read any args
sub usage {
    print "Usage : $0 [-c <config_file>] [-h <home_dir>]\n";
    exit(0);
}

{ my @ARGV_backup = @ARGV;
while(@ARGV) {
    my $p = shift(@ARGV);
    if($p eq '-c') {
        print("Missing config file name for -c\n"), usage() unless(@ARGV);
        $files{'cfg'} = shift(@ARGV);
    } elsif($p eq '-h') {
        print("Missing path name for -h\n"), usage() unless(@ARGV);
        $files{'homedir'} = shift(@ARGV);
    } else {
	usage();
    }
}
  @ARGV = @ARGV_backup; }

#############################
####### CONFIG FILE #########
#############################
$files{'basedir'} = $0;
if($0 =~ /\//) { # with at least one path
    $files{'basedir'} =~ s!/[^/]+$!!;
} else { # cwd
    $files{'basedir'} = '.';
}

include($files{'basedir'}."/timer.pl"); # Needed by config.pl
include($files{'basedir'}."/config.pl"); # Config file handling functions

unless(defined($files{'cfg'})) {
    $files{'cfg'} = $files{'homedir'}.'/config.xml';
}

# Create a default config file if needed
unless(-e $files{'cfg'}) {
    mkpath($files{'homedir'});
    create_default_config($files{'cfg'});
    exit(1);
}

exit(1) unless( load_lyca_config_file($files{'cfg'}) );

# Load the games definitions, if any
include($files{'basedir'}."/games.pl");
if(-e $files{'homedir'}.'/'.$files{'games'}) {
    unless( load_games_config_file($files{'homedir'}.'/'.$files{'games'}) ) {
	exit(1);
    }
}

# Load the current game settings
include($files{'basedir'}."/game_sets.pl");
exit(1) unless( read_game_sets() ); # load our %game_sets

# We need users.pl to load the users info file
include($files{'basedir'}."/users.pl"); # load our @userlist
exit(1) unless( read_user_infos() );

$::irc = new Net::IRC;
sub connect_to_IRC_server {
    our $conn = $::irc->newconn(
           'Server'      => $CFG{'server'},
	   'Port'        => $CFG{'port'}, 
	   'Nick'        => $CFG{'nick'},
	   'Ircname'     => $CFG{'irc_name'},
	   'Username'    => $CFG{'user_name'},
	   $CFG{'password'} eq '' ? () : 'Password' => $CFG{'password'},
	   'SSL'         => is_true($CFG{'use_SSL'}),
	   ($CFG{'max_bytes_sent'} && $CFG{'max_bytes_time'}) ?
	     ('Pacing'  => 1,
	      'MaxSend' => $CFG{'max_bytes_sent'},
	      'MaxTime' => $CFG{'max_bytes_time'},)
	   : ('Pacing'  => 0,)

	   );
    unless(defined($conn)) {
	die "Connection to $CFG{server}:$CFG{port} failed, exiting\n";
    }
}

# Let's go
connect_to_IRC_server();

#####################################
########### FUNCTIONS ###############
#####################################

# This stuff is from others files
include($files{'basedir'}."/send.pl");
include($files{'basedir'}."/commands.pl");
include($files{'basedir'}."/steps.pl");
include($files{'basedir'}."/admin.pl");
include($files{'basedir'}."/speech.pl");
include($files{'basedir'}."/hooks.pl");
include($files{'basedir'}."/actions.pl");

include($files{'basedir'}."/basics.pl");
include($files{'basedir'}."/jobs.pl");

#################################
########## MAIN LOOP ############
#################################

our %phs;
our %send_queue_time;
our $conn;
reset_game_vars(); # Let's do it

$::irc->timeout(0.20);
while($::run_mode == 1) {
    $::irc->do_one_loop();

    my $cur_time = time();

    # Timers checks
    check_timers($cur_time);

    # Send queued messages
    foreach my $msg (check_send_queue($cur_time)) {
	$$msg{'to'} = read_user_pnick($$msg{'to'});
	# Convert txt from perl internal string to the charset the channel uses.
	my ($rtxt, $txt);
	unless(ref($$msg{'txt'})) { # only encode if it's a scalar
	    $rtxt = do_encode($CFG{'charset'}, $$msg{'txt'});
	    $txt = $$msg{'txt'}; # keep this for print()
	}

	if($$msg{'type'} eq 'privmsg') {
	    $conn->privmsg($$msg{'to'}, $rtxt);
	    if($$msg{'to'} =~ /^\#/) {
		print "<".$CFG{'nick'}."/".$$msg{'to'}.">  ".$txt."\n";
	    } else {
		# Avoid printing the nick service password
		if(exists($CFG{'hacks'}{'service'}{'nick'})) {
		    my $nickserv = $CFG{'hacks'}{'service'}{'nick'}{'nick'};
		    my $password = $CFG{'hacks'}{'nick'}{'password'};
		    if(lc($$msg{'to'}) eq lc($nickserv)) {
			$txt =~ s/\Q$password/\*\*\*\*/;
		    }
		}
		print ">".$$msg{'to'}."<  ".$txt."\n";
	    }

	} elsif($$msg{'type'} eq 'notice') {
	    $conn->notice($$msg{'to'}, $rtxt);
	    print "|".$$msg{'to'}."|  ".$txt."\n";

	} elsif($$msg{'type'} eq 'mode') {
	    $txt = join(' ', map { read_user_pnick($_) } @{$$msg{'txt'}});
	    $conn->mode($$msg{'to'}, $txt);
	    if($txt eq "") {
		print "-> asking for ".$$msg{'to'}."'s modes\n";
	    } else {
		print "-> setting mode ".$txt." on ".$$msg{'to'}."\n";
	    }

	} elsif($$msg{'type'} eq 'invite') {
	    $conn->invite($$msg{'to'}, $rtxt);
	    print "-> inviting ".$$msg{'to'}." on ".$txt."\n";

	} elsif($$msg{'type'} eq 'who') {
	    $conn->who($$msg{'to'});
	    if($$msg{'to'} =~ /^\#/) {
		print "-> asking for ".$$msg{'to'}."'s userlist\n";
	    } else {
		print "-> /who'ing ".$$msg{'to'}."\n";
	    }
	} elsif($$msg{'type'} eq 'whois') {
	    $txt = join(',', map { read_user_pnick($_) } @{$$msg{'txt'}});
	    $conn->whois($txt);
	    print "-> /whois'ing $txt\n";
	} elsif($$msg{'type'} eq 'oper') {
	    $conn->oper($$msg{'to'}, $rtxt);
	    print "-> Asking for oper (as ".$$msg{'to'}.")\n";
	} elsif($$msg{'type'} eq 'raw') {
	    if(ref($$msg{'txt'}) eq 'CODE') {
		$txt = $$msg{'txt'}->();
	    } else {
		$txt = $$msg{'txt'};
	    }
	    $conn->sl($txt);
	    print "-> Sending raw line: ".$txt."\n"
	} elsif($$msg{'type'} eq 'cping') {
	    $conn->ctcp("PING", $$msg{'to'});
        } elsif($$msg{'type'} eq 'kick') {
	    $conn->kick($$msg{'chan'}, $$msg{'to'}, $$msg{'txt'});
	    print "-> Kicking $$msg{to} from $$msg{chan}, reason: $$msg{txt}\n";
        } elsif($$msg{'type'} eq 'part') {
	    $conn->part($$msg{'to'});
	    print "-> Leaving $$msg{to}\n";
        } elsif($$msg{'type'} eq 'join') {
	    $conn->join($$msg{'to'});
	    print "-> Joining $$msg{to}...\n";
	}

	# If there is an attached sub, execute it
	if(ref($$msg{'also_do'}) eq 'CODE') {
	    $$msg{'also_do'}->($cur_time);
	}
    
	if(is_true($CFG{'global_limit'})) {
	    $send_queue_time{'global'} = $cur_time + $$msg{'time'};
	} else {
	    $send_queue_time{ $$msg{'to'} } = $cur_time + $$msg{'time'};
	}
    }
}

# Save the synced data
$CFG{'storing'}{'sync'} = -1;
write_game_sets();
write_user_infos();

if($::run_mode == 0) {
    $conn->quit("Terminated.");
    $::irc->removeconn($conn);
    exit(0);
}

if($::run_mode == 2) {
    $conn->quit("Restarting...");
    $::irc->removeconn($conn);
    exec($0, @ARGV);
}

