# messages-en.pl
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


# This is the english messages file.

use utf8;

####################
##  Phases names  ##
####################
$messages{'phases'}{'werewolf'}{'name'} = 
  "the werewolves";

$messages{'phases'}{'day'}{'name'} = 
  "the villagers";


###################
##  Job's names  ##
###################
$messages{'jobs_name'}{'villager'} =
  "a villager";

$messages{'jobs_name'}{'werewolf'} =
  "a werewolf";

###################
##  Teams names  ##
###################
$messages{'team_name'}{'werewolf'} =
  "werewolf";

$messages{'team_name'}{'werewolves'} =
  "werewolves";

$messages{'team_name'}{'villager'} =
  "villager";

$messages{'team_name'}{'villagers'} =
  "villagers";

###################
##  Job's helps  ##
###################
# These are the $messages{'jobs_help'}{*} messages


################
##  Timeouts  ##
################
$messages{'timeouts'}{'announce_it'} = 
[ "You have %i seconds left." ];

$messages{'timeouts'}{'vote'}{'all'} = 
[ "Time's up! %s get the more voices." ]; # the one the players mostly vote for or against

$messages{'timeouts'}{'vote'}{'for'} = 
[ "Time's up! %s is elected." ]; # the one the players mostly vote for

$messages{'timeouts'}{'vote'}{'against'} = 
[ "The vote is over, %s will be lynched." ]; # the one the players mostly vote against

$messages{'timeouts'}{'werewolf_die_hunger'} = 
[ "Timeout reached! Unable to choose any "
 ."victim you all hunger to death." ];

$messages{'timeouts'}{'random'} = 
[ "Timeout reached! I randomly choosed %s for you." ];

$messages{'timeouts'}{'lost_player'} = 
[ "Beeing lost for too long, I kick %s out of the running game." ]; # the lost player

##########################
##  Timeouts announces  ##
##########################
# Note that some of these may be useless, but can be used anyway
$messages{'timeout_announce'}{'default'} = 
[ "You have %i seconds left." ];

$messages{'phases'}{'wait_play'}{'timeout_announce'} = 
[ "You have %i seconds to type \\cplay if you want to join this game." ]; # the timeout to announce

$messages{'phases'}{'wait_werewolves'}{'timeout_announce'} = 
[ "" ]; # the timeout to announce

#$messages{'phases'}{'werewolf'}{'timeout_announce'} = 
#[ "%i" ]; # the timeout to announce

#$messages{'phases'}{'day'}{'timeout_announce'} = 
#[ "%i" ]; # the timeout to announce

#$messages{'phases'}{'no_game'}{'timeout_announce'} = 
#[ "%i" ]; # the timeout to announce


##############
##  Errors  ##
##############
$messages{'errors'}{'unknown_ply'} = 
[ "Player '%s' is unknown to me..." ];

$messages{'errors'}{'dead_ply'} = 
[ "Impossible: %s is dead." ]; # the dead player

$messages{'errors'}{'alive_ply'} = 
[ "Impossible: %s is alive" ]; # the alive player

$messages{'errors'}{'ambigus_nick'} = 
[ "The nick %s is ambigous : is it %s ?" ]; # the ambigous nick, the list of possible choices

$messages{'errors'}{'unknown_card'} = 
[ "Unknown card: %s" ];

$messages{'errors'}{'unknown_cmd'} = 
[ "%s: no such command. Use \\chelp for a list of "
 ."available commands." ];

$messages{'errors'}{'unknown_phase'} = 
[ "Unknown phase: %s" ];

$messages{'errors'}{'not_moder'} = 
[ "Sorry, but the command %s needs moderator rights." ];

$messages{'errors'}{'not_admin'} = 
[ "Sorry, but the command %s needs admin rights." ];

$messages{'errors'}{'not_enouth_args'} = 
[ "Sorry, but the command %s needs at least %i "
 ."arguments." ];

$messages{'errors'}{'not_auth'} = 
[ "Sorry, but you are not allowed to use the %s command." ];

$messages{'errors'}{'not_alive'} = 
[ "Sorry, but you have to be alive to use %s." ];

$messages{'errors'}{'need_privmsg'} = 
[ "Sorry, but the %s command must be sent in private "
 ."(using /msg)." ];

$messages{'errors'}{'no_privmsg'} = 
[ "Sorry, but the command %s cannot be used in private." ];

$messages{'errors'}{'wrong_time_wait_for'} = 
[ "Sorry, it's not the moment for the %s command. You can only do it when it "
 ."is turn of %s." ];

$messages{'errors'}{'wrong_time'} = 
[ "Sorry, it's not the moment for the %s command." ]; # the command

$messages{'errors'}{'wrong_chan'} = 
[ "The %s command must be lauched from the channel %s." ]; # the command, the chan

$messages{'errors'}{'wrong_chan_hidden'} = 
[ "The %s command must be lauched from the night channel." ]; # the command

$messages{'errors'}{'exe_failed'} = 
[ "Failed to execute the %s command: %s." ];

$messages{'errors'}{'no_func_assoc'} = 
[ "Failed to execute the %s command: associated function "
 ."does not exist." ];

$messages{'errors'}{'not_an_int'} = 
[ "'%s' is not an integer." ]; # the non integer string

$messages{'errors'}{'in_game'} = 
[ "You have to wait for the end of the game." ];

$messages{'errors'}{'invalid_chars'} = 
[ "You just sent me invalid %s characters : %s" ]; # charset, message

$messages{'errors'}{'game_cmd'} = 
[ "You must be playing in a game, to be able to run the %s command." ];

$messages{'outgame'}{'warn_unident_player'} = 
[ "%s, if you are the player who just left, please first identify yourself "
 ."and then type \\cident, to come back into the game (%s seconds remaining)." ]; # disconnected player nick, remaining time (secs)

$messages{'outgame'}{'changing_night_channel'} = 
[ "Going to another night channel." ];


#######################
## Not game related  ##
#######################
$messages{'outgame'}{'not_enouth_players'} = 
[ "Damn, we must have at least %s players to launch a game: %s." ];

$messages{'outgame'}{'style_denied_start'} = 
[ "The selected style (%s) denies us to play with %i players." ]; # the style name, the wrong number of players

$messages{'outgame'}{'villagers_win'} = 
[ "Villagers win." ];

$messages{'outgame'}{'werewolves_win'} = 
[ "Werewolves (%s) win." ];

$messages{'outgame'}{'nobody_wins'} = 
[ "All the villagers died, so nobody wins." ];

$messages{'outgame'}{'survivor'} = 
[ "The only survivor is %s." ]; # the survivor

$messages{'outgame'}{'survivors'} = 
[ "The survivors are %s." ]; # the comma separated list of survivors

$messages{'outgame'}{'invite_werewolf'} = 
[ "You should join %s by typing /join %s" ];

##################
## Kick reasons ##
##################
$messages{'kick'}{'restart_game'} = 
[ "Starting a new game on %s." ]; # day channel

$messages{'kick'}{'end_game'} = 
[ "Game ended." ];

$messages{'kick'}{'day_channel_left'} = 
[ "You left %s, so you have nothing to do here anymore." ]; # day channel

$messages{'kick'}{'nick_spoof'} = 
[ "%s, you are attempting to spoof %s's nick." ]; # spoofer nick, spoofed nick


##########################
##  Deads announcements ##
##########################
$messages{'deads'}{'announce_job'} = 
[ "%s was %s." ];

$messages{'deads'}{'villagers_kill'} = 
[ "Villagers, you killed %s." ];

$messages{'deads'}{'werewol_u_kill'} = 
[ "Werewolves, you killed %s." ];

$messages{'deads'}{'werewol_have_killed'} = 
[ "Werewolves have just killed %s!" ];

$messages{'deads'}{'werewol_die_hunger'} = 
[ "The werewolves couldn't choose their victim and "
 ."they hungered to death." ];

$messages{'deads'}{'morning_no_dead'} = 
[ "Good news, everyone! Nobody was killed last night." ];

$messages{'deads'}{'morning_one_dead'} = 
[ "Villagers, last night one of us have been slaughtered "
 ."by the werewolves." ];

$messages{'deads'}{'morning_two_deads'} = 
[ "Two deads last night! As usual werewolves involvement is suspected." ];

$messages{'deads'}{'werevolves_kill'} = 
[ "%s was killed by the werewolves." ];

$messages{'deads'}{'last_werewolf_kill'} = 
[ "The last villager %s is slaughtered by the last werewolf." ]; # the killed player

$messages{'deads'}{'last_werewolves_kill'} = 
[ "The last villager %s is slaughtered by the last werewolves." ]; # the killed player


###########
## Votes ##
###########
$messages{'votes'}{'no_teamvote'}{'all'} = 
[ "You cannot give your voice to a member of your team." ];

$messages{'votes'}{'no_teamvote'}{'for'} = 
[ "You cannot vote for your team." ];

$messages{'votes'}{'no_teamvote'}{'against'} = 
[ "You cannot vote against your team." ];

$messages{'votes'}{'vote'}{'all'} = 
[ "You chose %s." ]; # the player you voted for or against

$messages{'votes'}{'vote'}{'for'} = 
[ "You voted for %s." ]; # the player you voted for

$messages{'votes'}{'vote'}{'against'} = 
[ "You voted against %s." ]; # the player you voted against

$messages{'votes'}{'change_vote'}{'all'} = 
[ "You changed your vote from %s to %s." ]; # old vote, new vote for or against

$messages{'votes'}{'change_vote'}{'for'} = 
[ "You voted for %s, but you change in favor of %s." ]; # old vote, new vote for

$messages{'votes'}{'change_vote'}{'against'} = 
[ "You voted against %s, but you change to %s." ]; # old vote, new vote against

$messages{'votes'}{'equal_voices'}{'all'} = 
[ "%s have equal voices." ]; # comma separated players with equal voices for or against

#$messages{'votes'}{'equal_voices'}{'for'} = 
#[ "%s" ]; # comma separated players with equal voices for

#$messages{'votes'}{'equal_voices'}{'against'} = 
#[ "%s" ]; # comma separated players with equal voices against

$messages{'votes'}{'silent_player'}{'all'} = 
[ "%s is the only one who has not voted yet." ]; # the player who have not voted for or against yet

#$messages{'votes'}{'silent_player'}{'for'} = 
#[ "%s" ]; # the player who have not voted for yet

#$messages{'votes'}{'silent_player'}{'against'} = 
#[ "%s" ]; # the player who have not voted against yet

$messages{'votes'}{'silent_players'}{'all'} = 
[ "%s have not voted." ]; # comma separated players who have not voted yet

#$messages{'votes'}{'silent_players'}{'for'} = 
#[ "%s" ]; # comma separated players who have not voted yet

#$messages{'votes'}{'silent_players'}{'against'} = 
#[ "%s" ]; # comma separated players who have not voted yet

$messages{'votes'}{'status_votes'}{'all'} = 
[ "%s gave their voices to %s." ]; # comma separated list of players who voted for or against, the targetted player

$messages{'votes'}{'status_votes'}{'for'} = 
[ "%s voted for %s." ]; # comma separated list of players who voted for, the targetted player

$messages{'votes'}{'status_votes'}{'against'} = 
[ "%s voted against %s." ]; # comma separated list of players who voted against, the targetted player

#$messages{'votes'}{'status_vote'}{'all'} = 
#[ "%s %s" ]; # the player who voted for or against, the targetted player

$messages{'votes'}{'status_vote'}{'for'} = 
[ "%s voted for %s." ]; # the player who voted for, the targetted player

$messages{'votes'}{'status_vote'}{'against'} = 
[ "%s voted against %s." ]; # the player who voted against, the targetted player

$messages{'votes'}{'nobody_voted'}{'all'} = 
[ "Nobody have voted yet." ];

$messages{'votes'}{'nobody_voted'}{'for'} = 
[ "Nobody voted for anyone." ];

$messages{'votes'}{'nobody_voted'}{'against'} = 
[ "Nobody voted against anyone." ];


################
##  Commands  ##
################
$messages{'cmds'}{'help'}{'descr'} = 
 "Show help about one or all command.";

$messages{'cmds'}{'help'}{'params'} = 
 "[command]";

$messages{'cmds'}{'help'}{'admin_commands'} = 
 "Administrator commands : %s"; # the list of the admin commands

$messages{'cmds'}{'help'}{'moder_commands'} = 
 "Moderator commands : %s"; # the list of the moderator commands

$messages{'cmds'}{'help'}{'game_commands'} = 
 "In-game commands : %s"; # the list of the game commands

$messages{'cmds'}{'help'}{'out_game_commands'} = 
 "Others : %s"; # the list of the out of the game commands

$messages{'cmds'}{'help'}{'specific'} = 
 "Type \\chelp <command> for a specific help about <command>."; # the command char prefix

$messages{'cmds'}{'help'}{'usage'} = 
 "Usage: %s";

$messages{'cmds'}{'start'}{'descr'} = 
 "Ask to start a new game.";

$messages{'cmds'}{'start'}{'run_already'} = 
[ "A game is already running." ];

$messages{'cmds'}{'start'}{'cannot_join'} = 
[ "Trying to join %s... relaunch \\cstart when it's done." ]; # the night channel, the command prefix

$messages{'cmds'}{'start'}{'cannot_join_hidden'} = 
[ "Trying to join another night channel... relaunch \\cstart when it's done." ]; # the command prefix

$messages{'cmds'}{'start'}{'not_op'} = 
 "I must be operator on both %s and %s to launch a "
."game";

$messages{'cmds'}{'start'}{'not_op_hidden'} = 
 "I must be operator on both %s and the night channel to launch a "
."game";

$messages{'cmds'}{'start'}{'no_werewolves'} = 
 "Can not start a new game: to get one werewolf, "
."we need at least %s players.";

$messages{'cmds'}{'start'}{'new_game'} = 
[ "New game requested by %s" ];

$messages{'cmds'}{'start'}{'your_card'} = 
[ "Your card is: %s" ];

$messages{'cmds'}{'start'}{'num_werewolf'} = 
[ "One of the %i innocents villagers is a "
 ."werewolf!" ];

$messages{'cmds'}{'start'}{'num_werewolves'} = 
[ "%i of the %i innocents villagers are "
 ."werewolves!" ];

$messages{'cmds'}{'stop'}{'descr'} = 
[ "Ask to stop a running game." ];

$messages{'cmds'}{'stop'}{'already_stop'} = 
[ "The game is already stopped." ];

$messages{'cmds'}{'stop'}{'game_stopped'} = 
[ "Game stopped by %s :(" ];

$messages{'cmds'}{'settimeout'}{'descr'} = 
 "Set a phase timeout.";

$messages{'cmds'}{'settimeout'}{'params'} = 
 "<phase> <seconds>";

$messages{'cmds'}{'settimeout'}{'example'} = 
[ "seer 30" ];

$messages{'cmds'}{'settimeout'}{'timeout_set'} = 
[ "Timeout for %s set to %i (maybe you should also "
 ."update the config file)." ];

$messages{'cmds'}{'showtimeouts'}{'descr'} = 
 "Show the current phase timeouts.";

$messages{'cmds'}{'showtimeouts'}{'timeouts'} = 
 "Current timeouts : %s";

$messages{'cmds'}{'setcards'}{'descr'} = 
 "Choose which special cards you want to use.";

$messages{'cmds'}{'setcards'}{'params'} = 
 "( (add|del) <card name> |  style <style>  |  nostyle )";

$messages{'cmds'}{'setcards'}{'example'} = 
[ "add cupid", "style classic" ];

$messages{'cmds'}{'setcards'}{'wrong_act'} = 
[ "You can add or delete cards set styles or not, but not '%s'" ];

$messages{'cmds'}{'setcards'}{'need_card'} = 
[ "You must specifiy a card." ];

$messages{'cmds'}{'setcards'}{'need_style'} = 
[ "You must specifiy a style." ];

$messages{'cmds'}{'setcards'}{'already_set'} = 
[ "%s is already added." ];

$messages{'cmds'}{'setcards'}{'already_unset'} = 
[ "%s is already removed." ];

$messages{'cmds'}{'setcards'}{'card_set'} = 
[ "%s has been added." ];

$messages{'cmds'}{'setcards'}{'card_set_but_style'} = 
[ "%s has been added (but the style %s remains activated)." ];

$messages{'cmds'}{'setcards'}{'card_unset'} = 
[ "%s has been removed." ];

$messages{'cmds'}{'setcards'}{'card_unset_but_style'} = 
[ "%s has been removed (but the style %s remains activated)." ];

$messages{'cmds'}{'setcards'}{'nostyle_set'} = 
[ "Now using the manually set card list." ];

$messages{'cmds'}{'setcards'}{'already_nostyle'} = 
[ "I am already not using the cards styles." ];

$messages{'cmds'}{'setcards'}{'style'} = 
[ "Now using the %s cards style." ]; # the just set style

$messages{'cmds'}{'setcards'}{'no_such_style'} = 
[ "No such style: %s." ]; # the not found style

$messages{'cmds'}{'showcards'}{'descr'} = 
 "Show the special cards that are used.";

$messages{'cmds'}{'showcards'}{'wrong_param'} = 
[ "Unknown parameter: %s." ]; # the wrong param

$messages{'cmds'}{'showcards'}{'cards_set'} = 
 "Cards manually set: %s."; # the comma separated list of the set cards

$messages{'cmds'}{'showcards'}{'cards_used'} = 
 "Using the special card(s) %s.";

$messages{'cmds'}{'showcards'}{'cards_unused'} = 
 "Others available : %s."; # the comma separated list of the unused cards

$messages{'cmds'}{'showcards'}{'no_cards'} = 
[ "No special cards are used." ];

$messages{'cmds'}{'showcards'}{'all_cards_used'} = 
[ "All the special cards are used." ];

$messages{'cmds'}{'showcards'}{'style'} = 
[ "Cards distribution is handled by the %s style." ]; # the used style

$messages{'cmds'}{'showcards'}{'nostyle'} = 
[ "No style used for the moment." ];

$messages{'cmds'}{'showstyle'}{'descr'} = 
 "Display the distribution styles list, or the details of a style."; # (One line length)

$messages{'cmds'}{'showstyle'}{'params'} = 
 "[<style>]";

$messages{'cmds'}{'showstyle'}{'all_styles'} = 
[ "Available distribution styles: %s." ]; # comma separated list of the style

$messages{'cmds'}{'showstyle'}{'no_such_style'} = 
[ "No such style: %s. Use \\cshowstyle to get a list of the available styles." ]; # the inexistant style

$messages{'cmds'}{'showstyle'}{'style_with_ply_limit'} = 
[ "Distribution style %s (needed number of players: %s):" ]; # the style name, the style players limits

$messages{'cmds'}{'showstyle'}{'style'} = 
[ "Distribution style %s:" ]; # the sytle name

$messages{'cmds'}{'showstyle'}{'no_jobs'} = 
[ "No special cards distributed." ];

$messages{'cmds'}{'showstyle'}{'job_always'} = 
 "always";

$messages{'cmds'}{'tutorial'}{'descr'} = 
 "Enable the in-game tutorial.";

$messages{'cmds'}{'tutorial'}{'tut_is_on'} = 
[ "Tutorial mode is currently enabled for you." ];

$messages{'cmds'}{'tutorial'}{'tut_is_off'} = 
[ "Tutorial mode is currently disabled for you." ];

$messages{'cmds'}{'tutorial'}{'tut_set_on'} = 
[ "Tutorial mode enabled." ];

$messages{'cmds'}{'tutorial'}{'tut_set_off'} = 
[ "Tutorial mode disabled." ];

$messages{'cmds'}{'tutorial'}{'tut_already_on'} = 
[ "Tutorial mode is already on." ];

$messages{'cmds'}{'tutorial'}{'tut_already_off'} = 
[ "Tutorial mode is already off." ];

$messages{'cmds'}{'tutorial'}{'wrong_param'} = 
[ "You can set tutorial mode to 'on' or 'off', "
 ."but not to '%s'." ];

$messages{'cmds'}{'vote'}{'descr'} = 
 "Vote for a player, it's usually used to kill him/her.";

$messages{'cmds'}{'vote'}{'params'} = 
 "<someone>";

$messages{'cmds'}{'vote'}{'example'} = 
[ "foobar" ];

$messages{'cmds'}{'unvote'}{'descr'} = 
 "Cancels your vote."; # (One line length)

$messages{'cmds'}{'unvote'}{'no_vote'} = 
[ "You have not voted yet." ];

$messages{'cmds'}{'unvote'}{'vote_canceled'} = 
[ "Your vote has been canceled." ];


$messages{'cmds'}{'play'}{'descr'} = 
 "Show me you want to play."; # (One line length)

$messages{'cmds'}{'play'}{'already_play'} = 
[ "You are already playing." ];

$messages{'cmds'}{'play'}{'now_play'} = 
[ "You play now." ];


$messages{'cmds'}{'unplay'}{'descr'} = 
 "Cancels your participation to a game."; # (One line length)

$messages{'cmds'}{'unplay'}{'no_play'} = 
[ "You are not playing yet." ];

$messages{'cmds'}{'unplay'}{'play_canceled'} = 
[ "You will no longer play." ];


$messages{'cmds'}{'votestatus'}{'descr'} = 
 "Prints who is voting for who"; # (One line length)


$messages{'cmds'}{'ident'}{'descr'} = 
 "Makes me identify someone, probably you."; # (One line length)

$messages{'cmds'}{'ident'}{'params'} = 
 "[unrecognized player]";

$messages{'cmds'}{'ident'}{'example'} = 
[ "foo_" ];

$messages{'cmds'}{'ident'}{'need_moder'} = 
[ "You need to be moderator if you want me to identify someone else "
 ."than you." ];


$messages{'cmds'}{'helps'}{'show_choices'} = 
[ "Possible choices: %s" ];

$messages{'cmds'}{'helps'}{'show_params'} = 
[ "Tell me your choice typing %s." ];

$messages{'cmds'}{'helps'}{'show_example'} = 
[ "Example: %s" ];


$messages{'cmds'}{'talkserv'}{'descr'} = 
 "Makes me say something to a service."; # (One line length)

$messages{'cmds'}{'talkserv'}{'params'} = 
 "<service> <message>";

$messages{'cmds'}{'talkserv'}{'example'} = 
[ "nick REGISTER bar foo\@bar.com",
  "nick GHOST foo hoppop",
  "chan REGISTER #village" ];

$messages{'cmds'}{'talkserv'}{'no_such_serv'} = 
[ "I don't know the '%s' service!\n"
 ."Please tell me that in the configuration file." ];


$messages{'cmds'}{'reloadconf'}{'descr'} = 
 "Makes me reload my config file."; # (One line length)

$messages{'cmds'}{'reloadconf'}{'error'} = 
[ "An error occured while loading %s:" ]; # the config file name

$messages{'cmds'}{'reloadconf'}{'reloaded'} = 
[ "Config file %s succesfully reloaded." ];


$messages{'cmds'}{'hlme'}{'descr'} = 
 "Handle if you want (or not) to be HL'ed, and until when."; # (One line length)

$messages{'cmds'}{'hlme'}{'wrong_param'} = 
[ "I can HL you forever, never, until you play a game or you quit, "
 ."but not '%s'." ]; # the wrong param

$messages{'cmds'}{'hlme'}{'hl'} = 
[ "%s is probably going to join this game." ]; # the hl'ed player

$messages{'cmds'}{'hlme'}{'hls'} = 
[ "%s may join this game." ]; # a comma separated list of hl'ed players

$messages{'cmds'}{'hlme'}{'forever'} = 
[ "I will HL you forever." ];

$messages{'cmds'}{'hlme'}{'quit'} = 
[ "I will HL you until you quit the channel." ];

$messages{'cmds'}{'hlme'}{'game'} = 
[ "I will HL you until you play a game." ];

$messages{'cmds'}{'hlme'}{'never'} = 
[ "I will never HL you." ];


$messages{'cmds'}{'activate'}{'descr'} = 
 "Activates me."; # (One line length)

$messages{'cmds'}{'activate'}{'now_active'} = 
[ "I am now activated." ];

$messages{'cmds'}{'activate'}{'already_active'} = 
[ "I am already activated." ];


$messages{'cmds'}{'deactivate'}{'descr'} = 
 "Deactivates me."; # (One line length)

$messages{'cmds'}{'deactivate'}{'now_noactive'} = 
[ "I am now deactivated." ];


#####################
##  Phase changes  ##
#####################
$messages{'time_to'}{'village_sleep'} = 
[ "The village is now going to sleep..." ];

$messages{'time_to'}{'werewolves_kill'} = 
[ "Werewolves, it's time to kill!" ];

$messages{'time_to'}{'find_werewolves'} = 
[ "Now it's time for you to find the werewolves!" ];

$messages{'time_to'}{'play'} = 
[ "%s, it's time to play !" ]; # comma separated list of players

########################
##  Welcome messages  ##
########################
$messages{'welcome'}{'welcome'} = 
[ "Welcome on %s ! I am the master of the game, and you can communiacate with "
 ."me using commands (\\chelp to get a list)." ]; # day channel name, command char prefix, command char prefix

$messages{'welcome'}{'wait_game_end'} = 
[ "A game is currently running. Please wait until it finishes, and then you "
 ."will be able to talk and participate." ];

$messages{'welcome'}{'wait_game_start'} = 
[ "No game is currently running. If there is enougth players, you can start it"
 ." typing \\cstart" ]; # command char prefix

$messages{'welcome'}{'back'} = 
[ "%s is back." ]; # player nick who came back

$messages{'welcome'}{'back_new_nick'} = 
[ "%s (previously %s) is back." ]; # player nick who came back, his previous nick
