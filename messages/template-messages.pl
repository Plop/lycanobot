# template-messages.pl
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


# This is a template file describing all the strings the bot can say
# or notice, in a specific language.
# If you want to make your own messages set, copy it and edit it as you want,
# taking example of the existing files. While you have not set a message yet,
# (i.e. it's still in comment), the bot loads the message in the
# default lang (english), so that a partial message file will result as a
# mix of english and your lang.
#
# The empty strings ("") mean that one message - and one only -
# have to be set. It can sometimes be divided into several messages, separated
# by an "\n". You can always replace them by an array of string (see below),
# but it's not recommended. There are cases when the message must be one line
# length, such as the commands descriptions. It's specified in comments.
#
# The arrays of strings ([ "" ]} mean that several messages can be said
# while they means the same thing, in order to diversify the sentences.
# There is no obligation to put several messages everywhere an array is,
# a simple string everywhere also work, but it's quite ugly.
#
# Some examples :
# - this will say "You are dead" then "and you cannot change your destiny"
#   in 2 messages :
#   "You are dead\nand you cannot change your destiny"
#
# - this will randomly say "You are dead", "This is your hour"
#   "You are doomed !" :
#   [ "You are dead", "This is your hour", "You are doomed !" ]
#
# The strings that contains some percents (%) need in-game information,
# that are added in the message using the printf way (see 'man 3 printf').
# These informations are described in comments
#
# Example :
# $messages{'cmds'}{'start'}{'not_op'} = 
# [ "%s %s" ]; # day channel name, night channel name
#
# That means this message takes two arguments, which are in comment.
# You can transform it to :
# $messages{'cmds'}{'start'}{'not_op'} = 
# [ "Damn, I can't start a new game :(\n";
#  ."I suspect that %s and %s cannot be joined..." ];
#
#
# Note here that any string can be a concatenation of several strings (using a
# dot), to make it easier to read.
# Also, because of perl's behaviour, single characters are actually
# strings, so don't be surprised if the command char prefix is showed as %s.
# Besides you have to put backslashes before some characters to prevent them
# from beeing interpreted by perl. These are : " $ @ \
#
# tip : while editing, regulary run `perl -c <your_file>` to prevent
#       accumulating syntax errors

use utf8;

####################
##  Phases names  ##
####################
#$messages{'phases'}{'werewolf'}{'name'} = 
#  "";

#$messages{'phases'}{'day'}{'name'} = 
#  "";


###################
##  Job's names  ##
###################
#$messages{'jobs_name'}{'villager'} =
#  "";

#$messages{'jobs_name'}{'werewolf'} =
#  "";


###################
##  Teams names  ##
###################
#$messages{'team_name'}{'werewolf'} =
#  "";

#$messages{'team_name'}{'werewolves'} =
#  "";

#$messages{'team_name'}{'villager'} =
#  "";

#$messages{'team_name'}{'villagers'} =
#  "";


###################
##  Job's helps  ##
###################
# These are the $messages{'jobs_help'}{*} messages


################
##  Timeouts  ##
################
#$messages{'timeouts'}{'vote'}{'all'} = 
#[ "%s" ]; # the one the players mostly vote for or against

#$messages{'timeouts'}{'vote'}{'for'} = 
#[ "%s" ]; # the one the players mostly vote for

#$messages{'timeouts'}{'vote'}{'against'} = 
#[ "%s" ]; # the one the players mostly vote against

#$messages{'timeouts'}{'werewolf_die_hunger'} = 
#[ "" ];

#$messages{'timeouts'}{'random'} = 
#[ "%s" ]; # the randomly chosen player

#$messages{'timeouts'}{'lost_player'} = 
#[ "%s" ]; # the lost player

##########################
##  Timeouts announces  ##
##########################
# Note that some of these may be useless, but can be used anyway
#$messages{'timeout_announce'}{'default'} = 
#[ "%i" ]; # the timeout to announce

#$messages{'phases'}{'wait_play'}{'timeout_announce'} = 
#[ "%i" ]; # the timeout to announce

#$messages{'phases'}{'wait_werewolves'}{'timeout_announce'} = 
#[ "%i" ]; # the timeout to announce

#$messages{'phases'}{'werewolf'}{'timeout_announce'} = 
#[ "%i" ]; # the timeout to announce

#$messages{'phases'}{'day'}{'timeout_announce'} = 
#[ "%i" ]; # the timeout to announce

#$messages{'phases'}{'no_game'}{'timeout_announce'} = 
#[ "%i" ]; # the timeout to announce


##############
##  Errors  ##
##############
#$messages{'errors'}{'unknown_ply'} = 
#[ "%s" ]; # the unknown player

#$messages{'errors'}{'dead_ply'} = 
#[ "%s" ]; # the dead player

#$messages{'errors'}{'alive_ply'} = 
#[ "%s" ]; # the alive player

#$messages{'errors'}{'ambigus_nick'} = 
#[ "%s %s" ]; # the ambigous nick, the comma separated possible choices

#$messages{'errors'}{'unknown_card'} = 
#[ "%s" ]; # the unknown card

#$messages{'errors'}{'unknown_cmd'} = 
#[ "%s" ]; # the command

#$messages{'errors'}{'unknown_phase'} = 
#[ "%s" ]; # the unknown phase

#$messages{'errors'}{'not_moder'} = 
#[ "%s" ]; # the moderator command

#$messages{'errors'}{'not_admin'} = 
#[ "%s" ]; # the admin command

#$messages{'errors'}{'not_enouth_args'} = 
#[ "%s %i" ]; # the command, the needed args number

#$messages{'errors'}{'not_auth'} = 
#[ "%s" ]; # the command the player cannot launch

#$messages{'errors'}{'not_alive'} = 
#[ "%s" ]; # the command the player cannot launch

#$messages{'errors'}{'need_privmsg'} = 
#[ "%s" ]; # the command

#$messages{'errors'}{'no_privmsg'} = 
#[ "%s" ]; # the command

#$messages{'errors'}{'wrong_time_wait_for'} = 
#[ "%s %s" ]; # the command, the comma separated list of valid phases names

#$messages{'errors'}{'wrong_time'} = 
#[ "%s" ]; # the command

#$messages{'errors'}{'wrong_chan'} = 
#[ "%s %s" ]; # the command, the chan

#$messages{'errors'}{'wrong_chan_hidden'} = 
#[ "%s" ]; # the command

#$messages{'errors'}{'exe_failed'} = 
#[ "%s %s" ]; # the command, the failed reason

#$messages{'errors'}{'no_func_assoc'} = 
#[ "%s" ]; # the command

#$messages{'errors'}{'not_an_int'} = 
#[ "%s" ]; # the non integer string

#$messages{'errors'}{'in_game'} = 
#[ "" ];

#$messages{'errors'}{'invalid_chars'} = 
#[ "%s %s" ]; # charset, message

#$messages{'errors'}{'game_cmd'} = 
#[ "%s" ]; # the unauthorized command


#######################
## Not game related  ##
#######################
#$messages{'outgame'}{'not_enouth_players'} = 
#[ "%s %s" ]; # the minimum number of players, a comma separated list of the needed jobs

#$messages{'outgame'}{'style_denied_start'} = 
#[ "%s %i" ]; # the style name, the wrong number of players

#$messages{'outgame'}{'villagers_win'} = 
#[ "" ];

#$messages{'outgame'}{'werewolves_win'} = 
#[ "" ];

#$messages{'outgame'}{'nobody_wins'} = 
#[ "" ];

#$messages{'outgame'}{'survivor'} = 
#[ "%s" ]; # the survivor

#$messages{'outgame'}{'survivors'} = 
#[ "%s" ]; # the comma separated list of survivors

#$messages{'outgame'}{'invite_werewolf'} = 
#[ "%s %s" ]; # night channel, night_channel

#$messages{'outgame'}{'warn_unident_player'} = 
#[ "%s %s" ]; # disconnected player nick, remaining time (secs)

#$messages{'outgame'}{'changing_night_channel'} = 
#[ "" ];


##################
## Kick reasons ##
##################
#$messages{'kick'}{'restart_game'} = 
#[ "%s" ]; # day channel

#$messages{'kick'}{'end_game'} = 
#[ "" ];

#$messages{'kick'}{'day_channel_left'} = 
#[ "%s" ]; # day channel

#$messages{'kick'}{'nick_spoof'} = 
#[ "%s %s" ]; # spoofer nick, spoofed nick


##########################
##  Deads announcements ##
##########################
#$messages{'deads'}{'announce_job'} = 
#[ "%s %s" ]; # dead one, his/her job

#$messages{'deads'}{'villagers_kill'} = 
#[ "%s" ]; # the killed player

#$messages{'deads'}{'werewol_u_kill'} = 
#[ "%s" ]; # the dead player

#$messages{'deads'}{'werewol_have_killed'} = 
#[ "%s" ]; # the killed player

#$messages{'deads'}{'werewol_die_hunger'} = 
#[ "" ];

#$messages{'deads'}{'morning_no_dead'} = 
#[ "" ];

#$messages{'deads'}{'morning_one_dead'} = 
#[ "" ];

#$messages{'deads'}{'morning_two_deads'} = 
#[ "" ];

#$messages{'deads'}{'werevolves_kill'} = 
#[ "%s" ];

#$messages{'deads'}{'last_werewolf_kill'} = 
#[ "%s" ]; # the killed player

#$messages{'deads'}{'last_werewolves_kill'} = 
#[ "%s" ]; # the killed player


###########
## Votes ##
###########
#$messages{'votes'}{'no_teamvote'}{'all'} = 
#[ "" ];

#$messages{'votes'}{'no_teamvote'}{'for'} = 
#[ "" ];

#$messages{'votes'}{'no_teamvote'}{'against'} = 
#[ "" ];

#$messages{'votes'}{'vote'}{'all'} = 
#[ "%s" ]; # the player you voted for or against

#$messages{'votes'}{'vote'}{'for'} = 
#[ "%s" ]; # the player you voted for

#$messages{'votes'}{'vote'}{'against'} = 
#[ "%s" ]; # the player you voted against

#$messages{'votes'}{'change_vote'}{'all'} = 
#[ "%s %s" ]; # old vote, new vote for or against

#$messages{'votes'}{'change_vote'}{'for'} = 
#[ "%s %s" ]; # old vote, new vote for

#$messages{'votes'}{'change_vote'}{'against'} = 
#[ "%s %s" ]; # old vote, new vote against

#$messages{'votes'}{'equal_voices'}{'all'} = 
#[ "%s" ]; # comma separated players with equal voices for or against

#$messages{'votes'}{'equal_voices'}{'for'} = 
#[ "%s" ]; # comma separated players with equal voices for

#$messages{'votes'}{'equal_voices'}{'against'} = 
#[ "%s" ]; # comma separated players with equal voices against

#$messages{'votes'}{'silent_player'}{'all'} = 
#[ "%s" ]; # the player who have not voted for or against yet

#$messages{'votes'}{'silent_player'}{'for'} = 
#[ "%s" ]; # the player who have not voted for yet

#$messages{'votes'}{'silent_player'}{'against'} = 
#[ "%s" ]; # the player who have not voted against yet

#$messages{'votes'}{'silent_players'}{'all'} = 
#[ "%s" ]; # comma separated players who have not voted yet

#$messages{'votes'}{'silent_players'}{'for'} = 
#[ "%s" ]; # comma separated players who have not voted yet

#$messages{'votes'}{'silent_players'}{'against'} = 
#[ "%s" ]; # comma separated players who have not voted yet

#$messages{'votes'}{'status_votes'}{'all'} = 
#[ "%s %s" ]; # comma separated list of players who voted for or against, the targetted player

#$messages{'votes'}{'status_votes'}{'for'} = 
#[ "%s %s" ]; # comma separated list of players who voted for, the targetted player

#$messages{'votes'}{'status_votes'}{'against'} = 
#[ "%s %s" ]; # comma separated list of players who voted against, the targetted player

#$messages{'votes'}{'status_vote'}{'all'} = 
#[ "%s %s" ]; # the player who voted for or against, the targetted player

#$messages{'votes'}{'status_vote'}{'for'} = 
#[ "%s %s" ]; # the player who voted for, the targetted player

#$messages{'votes'}{'status_vote'}{'against'} = 
#[ "%s %s" ]; # the player who voted against, the targetted player

#$messages{'votes'}{'nobody_voted'}{'all'} = 
#[ "" ];

#$messages{'votes'}{'nobody_voted'}{'for'} = 
#[ "" ];

#$messages{'votes'}{'nobody_voted'}{'against'} = 
#[ "" ];

################
##  Commands  ##
################
## help
#$messages{'cmds'}{'help'}{'descr'} = 
# ""; # (One line length)

#$messages{'cmds'}{'help'}{'params'} = 
# ""; # (One line length)

#$messages{'cmds'}{'help'}{'admin_commands'} = 
# "%s"; # the list of the admin commands

#$messages{'cmds'}{'help'}{'moder_commands'} = 
# "%s"; # the list of the moderator commands

#$messages{'cmds'}{'help'}{'game_commands'} = 
# "%s"; # the list of the game commands

#$messages{'cmds'}{'help'}{'out_game_commands'} = 
# "%s"; # the list of the out of the game commands

#$messages{'cmds'}{'help'}{'specific'} = 
# "";

#$messages{'cmds'}{'help'}{'usage'} = 
# "%s"; # the usage

## start
#$messages{'cmds'}{'start'}{'descr'} = 
# ""; # (One line length)

#$messages{'cmds'}{'start'}{'run_already'} = 
#[ "" ];

#$messages{'cmds'}{'start'}{'cannot_join'} = 
#[ "%s %s" ]; # the night channel, the command prefix

#$messages{'cmds'}{'start'}{'cannot_join_hidden'} = 
#[ "%s" ]; # the command prefix

#$messages{'cmds'}{'start'}{'not_op'} = 
#[ "%s %s" ]; # the day channel, the night channel

#$messages{'cmds'}{'start'}{'not_op_hidden'} = 
#[ "%s" ]; # the day channel

#$messages{'cmds'}{'start'}{'no_werewolves'} = 
#[ "%s" ]; # the minimum number of players

#$messages{'cmds'}{'start'}{'new_game'} = 
#[ "%s" ]; # game caller

#$messages{'cmds'}{'start'}{'your_card'} = 
#[ "%s" ]; # the card

#$messages{'cmds'}{'start'}{'num_werewolf'} = 
#[ "%i" ]; # the number of players

#$messages{'cmds'}{'start'}{'num_werewolves'} = 
#[ "%i %i" ]; # werewolves number, players number

## stop
#$messages{'cmds'}{'stop'}{'descr'} = 
# ""; # (One line length)

#$messages{'cmds'}{'stop'}{'already_stop'} = 
#[ "" ];

#$messages{'cmds'}{'stop'}{'game_stopped'} = 
#[ "%s" ]; # game stopper

## settimeout
#$messages{'cmds'}{'settimeout'}{'descr'} = 
# ""; # (One line length)

#$messages{'cmds'}{'settimeout'}{'params'} = 
# "";

#$messages{'cmds'}{'settimeout'}{'example'} = 
#[ "" ];

#$messages{'cmds'}{'settimeout'}{'timeout_set'} = 
#[ "%s %i" ]; # the phase, the timeout

## showtimeouts
#$messages{'cmds'}{'showtimeouts'}{'descr'} = 
# ""; # (One line length)

#$messages{'cmds'}{'showtimeouts'}{'timeouts'} = 
# "%s"; # comma separated list of the timeouts (in secs)

## setcards
#$messages{'cmds'}{'setcards'}{'descr'} = 
# ""; # (One line length)

#$messages{'cmds'}{'setcards'}{'params'} = 
# "";

#$messages{'cmds'}{'setcards'}{'example'} = 
#[ "" ];

#$messages{'cmds'}{'setcards'}{'wrong_act'} = 
#[ "%s" ]; # the wrong action

#$messages{'cmds'}{'setcards'}{'need_card'} = 
#[ "" ];

#$messages{'cmds'}{'setcards'}{'need_style'} = 
#[ "" ];

#$messages{'cmds'}{'setcards'}{'already_set'} = 
#[ "%s" ]; # the already added card

#$messages{'cmds'}{'setcards'}{'already_unset'} = 
#[ "%s" ]; # the already removed card

#$messages{'cmds'}{'setcards'}{'card_set'} = 
#[ "%s" ]; # the card which have been set

#$messages{'cmds'}{'setcards'}{'card_set_but_style'} = 
#[ "%s %s" ]; # the card which have been set, the current used style

#$messages{'cmds'}{'setcards'}{'card_unset'} = 
#[ "%s" ]; # the card which have been unset

#$messages{'cmds'}{'setcards'}{'card_unset_but_style'} = 
#[ "%s %s" ]; # the card which have been unset, the current used style

#$messages{'cmds'}{'setcards'}{'nostyle_set'} = 
#[ "" ];

#$messages{'cmds'}{'setcards'}{'already_nostyle'} = 
#[ "" ];

#$messages{'cmds'}{'setcards'}{'style'} = 
#[ "%s" ]; # the just set style

#$messages{'cmds'}{'setcards'}{'no_such_style'} = 
#[ "%s" ]; # the not found style

## showcards
#$messages{'cmds'}{'showcards'}{'descr'} = 
# ""; # (One line length)

#$messages{'cmds'}{'showcards'}{'wrong_param'} = 
#[ "%s" ]; # the wrong param

#$messages{'cmds'}{'showcards'}{'cards_set'} = 
# "%s"; # the comma separated list of the set cards

#$messages{'cmds'}{'showcards'}{'cards_used'} = 
# "%s"; # the comma separated list of the used cards

#$messages{'cmds'}{'showcards'}{'cards_unused'} = 
# "%s"; # the comma separated list of the unused cards

#$messages{'cmds'}{'showcards'}{'no_cards'} = 
#[ "" ];

#$messages{'cmds'}{'showcards'}{'all_cards_used'} = 
#[ "" ];

#$messages{'cmds'}{'showcards'}{'style'} = 
#[ "%s" ]; # the used style

#$messages{'cmds'}{'showcards'}{'nostyle'} = 
#[ "" ];

## showstyle
#$messages{'cmds'}{'showstyle'}{'descr'} = 
# ""; # (One line length)

#$messages{'cmds'}{'showstyle'}{'params'} = 
# "";

#$messages{'cmds'}{'showstyle'}{'all_styles'} = 
#[ "%s" ]; # comma separated list of the style

#$messages{'cmds'}{'showstyle'}{'no_such_style'} = 
#[ "%s" ]; # the inexistant style

#$messages{'cmds'}{'showstyle'}{'style_with_ply_limit'} = 
#[ "%s %s" ]; # the style name, the style players limits

#$messages{'cmds'}{'showstyle'}{'style'} = 
#[ "%s" ]; # the sytle name

#$messages{'cmds'}{'showstyle'}{'no_jobs'} = 
#[ "" ];

#$messages{'cmds'}{'showstyle'}{'job_always'} = 
# "";

## tutorial
#$messages{'cmds'}{'tutorial'}{'descr'} = 
# ""; # (One line length)

#$messages{'cmds'}{'tutorial'}{'tut_is_on'} = 
#[ "" ];

#$messages{'cmds'}{'tutorial'}{'tut_is_off'} = 
#[ "" ];

#$messages{'cmds'}{'tutorial'}{'tut_set_on'} = 
#[ "" ];

#$messages{'cmds'}{'tutorial'}{'tut_set_off'} = 
#[ "" ];

#$messages{'cmds'}{'tutorial'}{'tut_already_on'} = 
#[ "" ];

#$messages{'cmds'}{'tutorial'}{'tut_already_off'} = 
#[ "" ];

#$messages{'cmds'}{'tutorial'}{'wrong_param'} = 
#[ "%s" ]; # the wrong param

## vote
#$messages{'cmds'}{'vote'}{'descr'} = 
# ""; # (One line length)

#$messages{'cmds'}{'vote'}{'params'} = 
# "";

#$messages{'cmds'}{'vote'}{'example'} = 
#[ "" ];

## unvote
#$messages{'cmds'}{'unvote'}{'descr'} = 
# ""; # (One line length)

#$messages{'cmds'}{'unvote'}{'no_vote'} = 
#[ "" ];

#$messages{'cmds'}{'unvote'}{'vote_canceled'} = 
#[ "" ];

### play
#$messages{'cmds'}{'play'}{'descr'} = 
# ""; # (One line length)

#$messages{'cmds'}{'play'}{'already_play'} = 
#[ "" ];

#$messages{'cmds'}{'play'}{'now_play'} = 
#[ "" ];

## unplay
#$messages{'cmds'}{'unplay'}{'descr'} = 
# ""; # (One line length)

#$messages{'cmds'}{'unplay'}{'no_play'} = 
#[ "" ];

#$messages{'cmds'}{'unplay'}{'play_canceled'} = 
#[ "" ];

## votestatus
#$messages{'cmds'}{'votestatus'}{'descr'} = 
# ""; # (One line length)

## talkserv
#$messages{'cmds'}{'talkserv'}{'descr'} = 
# ""; # (One line length)

#$messages{'cmds'}{'talkserv'}{'params'} = 
# "";

#$messages{'cmds'}{'talkserv'}{'example'} = 
#[ "" ];

#$messages{'cmds'}{'talkserv'}{'no_such_serv'} = 
#[ "%s" ]; # the unknown service

## reloadconf
#$messages{'cmds'}{'reloadconf'}{'descr'} = 
# ""; # (One line length)

#$messages{'cmds'}{'reloadconf'}{'error'} = 
#[ "%s" ]; # the config file name

#$messages{'cmds'}{'reloadconf'}{'reloaded'} = 
#[ "%s" ]; # the config file name

## ident
#$messages{'cmds'}{'ident'}{'descr'} = 
# ""; # (One line length)

#$messages{'cmds'}{'ident'}{'params'} = 
# "";

#$messages{'cmds'}{'ident'}{'example'} = 
#[ "" ];

#$messages{'cmds'}{'ident'}{'need_admin'} = 
#[ "" ];

## hlme
#$messages{'cmds'}{'hlme'}{'descr'} = 
# ""; # (One line length)

#$messages{'cmds'}{'hlme'}{'wrong_param'} = 
#[ "%s" ]; # the wrong param

#$messages{'cmds'}{'hlme'}{'hl'} = 
#[ "%s" ]; # the hl'ed player

#$messages{'cmds'}{'hlme'}{'hls'} = 
#[ "%s" ]; # a comma separated list of hl'ed players

#$messages{'cmds'}{'hlme'}{'forever'} = 
#[ "" ];

#$messages{'cmds'}{'hlme'}{'quit'} = 
#[ "" ];

#$messages{'cmds'}{'hlme'}{'game'} = 
#[ "" ];

#$messages{'cmds'}{'hlme'}{'never'} = 
#[ "" ];

## activate
#$messages{'cmds'}{'activate'}{'descr'} = 
# ""; # (One line length)

#$messages{'cmds'}{'activate'}{'now_active'} = 
#[ "" ];

#$messages{'cmds'}{'activate'}{'already_active'} = 
#[ "" ];

## deactivate
#$messages{'cmds'}{'deactivate'}{'descr'} = 
# ""; # (One line length)

#$messages{'cmds'}{'deactivate'}{'now_noactive'} = 
#[ "" ];

## commands helps
#$messages{'cmds'}{'helps'}{'show_choices'} = 
#[ "%s" ]; # comma separated choices

#$messages{'cmds'}{'helps'}{'show_params'} = 
#[ "%s" ]; # the command and its params

#$messages{'cmds'}{'helps'}{'show_example'} = 
#[ "%s" ]; # the command example


#####################
##  Phase changes  ##
#####################
#$messages{'time_to'}{'village_sleep'} = 
#[ "" ];

#$messages{'time_to'}{'werewolves_kill'} = 
#[ "" ];

#$messages{'time_to'}{'find_werewolves'} = 
#[ "" ];

#$messages{'time_to'}{'play'} = 
#[ "" ];


########################
##  Welcome messages  ##
########################
#$messages{'welcome'}{'welcome'} = 
#[ "%s" ]; # day channel name

#$messages{'welcome'}{'wait_game_end'} = 
#[ "" ];

#$messages{'welcome'}{'wait_game_start'} = 
#[ "" ];

#$messages{'welcome'}{'back'} = 
#[ "%s" ]; # player nick who came back

#$messages{'welcome'}{'back_new_nick'} = 
#[ "%s %s" ]; # player nick who came back, his previous nick
