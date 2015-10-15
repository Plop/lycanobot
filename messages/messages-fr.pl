# messages-fr.pl
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
#  ."I suspect that %s and %s cannot be joined…" ];
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
$messages{'phases'}{'werewolf'}{'name'} =
  "les loups-garous";

$messages{'phases'}{'day'}{'name'} = 
  "les villageois";


###################
##  Teams names  ##
###################
$messages{'team_name'}{'werewolf'} =
  "loup-garou";

$messages{'team_name'}{'werewolves'} =
  "loups-garous";

$messages{'team_name'}{'villager'} =
  "villageois";

$messages{'team_name'}{'villagers'} =
  "villageois";


###################
##  Job's names  ##
###################
$messages{'jobs_name'}{'villager'} =
  "un-e villageois-e";
$messages{'jobs_name'}{'werewolf'} =
  "un loup-garou";


###################
##  Job's helps  ##
###################
# These are the $messages{'jobs_help'}{*} messages


################
##  Timeouts  ##
################
$messages{'timeouts'}{'vote'}{'all'} = 
[ "C'est fini ! %s a remporté "
 ."le plus de voix." ]; # the one the players mostly vote for or against

$messages{'timeouts'}{'vote'}{'for'} = 
[ "Temps écoulé ! La personne élue "
 ."par le vote est %s." ]; # the one the players mostly vote for

$messages{'timeouts'}{'vote'}{'against'} = 
[   "Temps écoulé ! La personne condamnée "
 ."par le vote est %s." ]; # the one the players mostly vote against

$messages{'timeouts'}{'werewolf_die_hunger'} = 
[ "Trop tard ! Vous mourrez tous de faim car "
 ."vous n'avez désigné personne !",
  "Vous n'avez pas été assez rapide… la faim vous a terrassé !" ];

$messages{'timeouts'}{'random'} = 
[ "Temps écoulé ! Je déciderai donc à votre "
 ."place : %s" ]; # the randomly chosen player

$messages{'timeouts'}{'lost_player'} = 
[ "%s ne revenant pas, je me vois dans l'obligation de l'éjecter "
 ."de la partie en cours.",
  "Étant porté-e disparu-e depuis trop longtemps, %s est retiré-e "
 ."de la partie." ]; # the lost player

##########################
##  Timeouts announces  ##
##########################
$messages{'timeout_announce'}{'default'} = 
[ "Vous avez %i secondes." ]; # the timeout to announce

$messages{'phases'}{'wait_play'}{'timeout_announce'} = 
[ "Je vous laisse %i secondes pour taper \\cplay, "
 ."si vous voulez rejoindre cette partie." ]; # the timeout to announce

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
[ "%s est inconnu-e au bataillon !",
  "Je ne connais personne sous le pseudo %s !\n"
 ."Vérifiez qu'il s'agit bien d'une appellation "
 ."d'origine contrôlée." ]; # the unknown player

$messages{'errors'}{'dead_ply'} = 
[ "Impossible : %s est mort-e." ]; # the dead player

$messages{'errors'}{'alive_ply'} = 
[ "Impossible : %s est vivant-e." ]; # the alive player

$messages{'errors'}{'unknown_card'} = 
[ "Carte inconnue : %s." ]; # the unknown card

$messages{'errors'}{'unknown_cmd'} = 
[ "Commande %s inconnue. Tapez \\chelp pour obtenir la liste des commandes." ];
# the command, the commands prefix char

$messages{'errors'}{'ambigus_nick'} = 
[ "Le nom %s est ambigu : est-ce %s ?" ]; # the ambigous nick, the list of possible choices

$messages{'errors'}{'unknown_phase'} = 
[ "Phase inconnue : %s." ]; # the unknown phase

$messages{'errors'}{'not_moder'} = 
[ "La commande %s nécessite la qualité de modérateur.",
  "Ah ah ! Que croyez-vous donc ?! %s doit être lancée "
 ."par un modérateur !",
  "Seuls les grands maîtres modérateurs détiennent le "
 ."pouvoir le lancer %s." ]; # the moderator command

$messages{'errors'}{'not_admin'} = 
[ "La commande %s nécessite la qualité d'administrateur.",
  "Ah ah ! Que croyez-vous donc ?! %s doit être lancée "
 ."par un administrateur !",
  "Seuls les grands maîtres administrateurs détiennent le "
 ."pouvoir le lancer %s." ]; # the admin command

$messages{'errors'}{'not_enouth_args'} = 
[ "La commande %s nécessite au minimum %i paramètre(s).",
  "Pour la commande %s, vous devez donner "
 ."au moins %i paramètre(s)." ]; # the command, the needed args number

$messages{'errors'}{'not_auth'} = 
[ "Désolé, mais vous ne pouvez pas lancer %s.",
  "Nonon, vous n'avez pas le droit de faire %s.",
  "Hé, qui vous autoriserais à faire %s ?\n"
  ."Certainement pas moi !" ]; # the command the player cannot launch

$messages{'errors'}{'not_alive'} = 
[ "Désolé, mais vous devez être en vie pour lancer la commande %s." ];

$messages{'errors'}{'need_privmsg'} = 
[ "La commande %s doit être lancée en privé (/msg)." ]; # the command

$messages{'errors'}{'no_privmsg'} = 
[ "La commande %s ne peut pas être lancée en privé." ]; # the command

$messages{'errors'}{'wrong_time_wait_for'} = 
[ "Désolé, c'est pas le moment pour %s. Attendez que j'appelle %s.",
  "Hé, %s c'est pas maintenant, mais quand j'appelle %s." ]; # the command, the comma separated list of valid phases names

$messages{'errors'}{'wrong_time'} = 
[ "Désolé, c'est pas le moment pour %s.",
  "Hé, %s c'est pas maintenant !" ]; # the command

$messages{'errors'}{'wrong_chan'} = 
[ "La commande %s doit être lancée depuis le salon %s." ]; # the command, the chan

$messages{'errors'}{'wrong_chan_hidden'} = 
[ "La commande %s doit être lancée depuis le salon de nuit." ]; # the command

$messages{'errors'}{'exe_failed'} = 
[ "Erreur d'execution de %s : %s" ]; # the command, the failed reason

$messages{'errors'}{'no_func_assoc'} = 
[ "Il n'y a pas encore de fonction associée à %s." ]; # the command

$messages{'errors'}{'not_an_int'} = 
[ "'%s' n'est pas un nombre !" ]; # the non integer string

$messages{'errors'}{'in_game'} = 
[ "Vous devez attendre la fin de la partie.",
  "La partie doit d'abord se terminer." ];

$messages{'errors'}{'invalid_chars'} = 
[ "Vous m'envoyez des caractères invalides en %s : %s" ]; # charset, message

$messages{'errors'}{'game_cmd'} = 
[ "La commande %s est réservée aux joueurs, or là vous ne jouez pas.",
  "Seules les personnes qui jouent dans une partie peuvent utiliser %s.",
  "Vous devez prendre part à une partie pour pouvoir lancer %s." ]; # the unauthorized command

#######################
## Not game related  ##
#######################
$messages{'outgame'}{'not_enouth_players'} = 
[ "Mince, il fallait au minimum %s joueurs pour lancer la partie: %s." ]; # the minimum number of players, a comma separated list of the needed jobs

$messages{'outgame'}{'style_denied_start'} = 
[ "Oups, avec le style %s on ne peut pas démarrer de partie à %i joueurs.",
  "Ah, c'est déjà fini : impossible avec le style %s de jouer à %i joueurs.",
  "Bon, ça sera pour une prochaine fois. Le style %s impose de ne pas jouer "
 ."à %i joueurs." ]; # the style name, the wrong number of players

$messages{'outgame'}{'villagers_win'} = 
[ "Les villageois ont triomphé par leur intelligence supérieure !\n"
 ."Loups-garous %s, vous avez été défaits par une bande de pauvres "
 ."villageois…",
  "Longue vie aux victorieux villageois ! Et loups-garous (%s), rhabillez"
 ."-vous !",
  "Villageois, vous avez gagné une bataille contre %s, mais vous n'avez peut"
 ."-être pas gagné la guerre.\nNe dormez que d'un œil, jusqu'à la prochaine "
 ."partie.",
  "Les loups-garous (%s) sont ri-di-cu-li-sés !\nIls n'ont rien pu faire "
 ."contre les villageois, et leurs carcasses sont jetées sur le fumier "
 ."du village maintenant purifié.",
  "Les villageois sont venus … ils ont vu … et ils ont vaincu %s.",
  "Le village célébre sa victoire par une fête démente autour du feu "
 ."où rotissent les loups-garous (%s).",
  "Le village peut maintenant respirer en paix.\nEt les âmes des "
 ."loups-garous (%s) reposer en paix.",
  "Loups-garous %s, vous avez été défaits par les troupes villageoises …\n"
 ."Prendrez-vous votre revanche dans une nouvelle partie ?" ];

$messages{'outgame'}{'werewolves_win'} = 
[ "Villageois, les loups-garous (%s) vous ont tous mangés dans leurs accès de "
 ."folie nocturne.\nVous vous êtes bien battus. Aurez-vous le courage de "
 ."laver votre honneur et de venger vos amis tombés au combat ?",
  "Le maître de jeu adresse toutes ses félicitations aux valeureux loups-"
 ."garous (%s) dont le génie et la perfidie ont permis d'en finir avec ces "
 ."villageois tout de même vaillants.",
  "L'instinct animal et bestial des loups-garous (%s) l'a emporté sur la "
 ."candeur des villageois qui dormaient à poings trop fermés…" ];

$messages{'outgame'}{'nobody_wins'} = 
[ "Le climat de terreur a conduit le village à l'apocalyse…\n"
 ."Il ne reste aucun survivant !",
  "Tout le monde est mort, et le village est maintenant hanté à jamais par "
 ."les âmes des villageois.",
  "La hantise ambiante a poussé les villageois à s'entretuer jusqu'au "
 ."dernier." ];

$messages{'outgame'}{'survivor'} = 
[ "L'unique survivant-e est %s.",
  "L'ultime rescapé-e est %s.",
  "Seul l'audacieux-se %s est sortie indemne de cette partie.",
  "%s s'en sort tout-e seul-e et règne désormais en maître absolu "
 ."sur le village … vide.",
  "Malin, %s a laissé chacun se faire tuer et s'en va maintenant avec "
 ."le magot de tout le monde.",
  "L'intrépide %s a su tirer son épingle du jeu en gagnant courageusement "
 ."cette partie." ]; # the survivor

$messages{'outgame'}{'survivors'} = 
[ "%s sont les seul-e-s survivant-e-s.",
  "Les valeureux-ses %s ont remarquablement su rester vivants pendant toute "
 ."la partie.",
  "Les ultimes survivant-e-s sont %s.",
  "La bravoure et l'assurance de %s les ont nettement tiré d'affaire." ]; # the comma separated list of survivors

# ... /join %s )
#             ^
# This space allows joining using the right clic without having the ')' in the
# channel name.
$messages{'outgame'}{'invite_werewolf'} = 
[ "Vous êtes convié sur %s (tapez /join %s )." ]; # night channel, night_channel

$messages{'outgame'}{'warn_unident_player'} = 
[ "%s, si vous êtes le joueur qui a quitté tout à l'heure, veuillez d'abord "
 ."vous identifier puis taper \\cident pour revenir dans la partie (reste %s secondes)." ]; # disconnected player nick, remaining time (secs)

$messages{'outgame'}{'changing_night_channel'} = 
[ "Changement de salon de nuit." ];


##################
## Kick reasons ##
##################
$messages{'kick'}{'restart_game'} = 
[ "Nouvelle partie lancée sur %s." ];

$messages{'kick'}{'end_game'} = 
[ "Partie terminée." ];

$messages{'kick'}{'day_channel_left'} = 
[ "Si vous partez de %s, vous n'avez plus rien à faire ici." ]; # day channel

$messages{'kick'}{'nick_spoof'} = 
[ "%s, vous tentez d'usurper le pseudo de %s." ]; # spoofer nick, spoofed nick


##########################
##  Deads announcements ##
##########################
$messages{'deads'}{'announce_job'} = 
[ "%s était %s.",
  "%s n'était autre que … %s.",
  "Derrière le visage de %s se cachait %s.",
  "La mort libère le vrai visage de %s qui était … %s.",
#  "Une fois la colère passée, les villageois réalisent qu'ils viennent de "
# ."tuer %s.",
  "Incroyable mais vrai ! %s était %s.",
  "L'identité de %s était %s." ]; # dead one, his/her job

$messages{'deads'}{'villagers_kill'} = 
[ "Vous avez tué %s.",
  "%s passe sur le bûcher.",
  "%s expie ses fautes par le feu.",
  "%s connaît déjà l'enfer.",
  "%s - R.I.P.",
  "La grande faucheuse a emporté %s.",
  "%s meurt dans d'atroces souffrances.",
  "Paix à l'âme de %s.",
  "Vous n'avez pas cru %s ? Et bien vous l'aurez cuit.",
  "%s n'est plus qu'un tas de cendre.",
  "%s a beau plaider son innocence les villageois l'exécutent.",
  "Il en fallait bien un alors pourquoi pas %s !",
  "%s n'a pas le temps de comprendre qu'une faucille se plante dans son dos.",
  "%s hurle de douleur sous les coups mortels des villageois.",
  "Aveuglés par la rage, les villageois lapident %s.",
  "Les villageois font boire la ciguë à %s.",
  "Les villageois n'ont pas envie de réfléchir plus longtemps et %s "
 ."est désigné-e à la vindicte populaire.",
  "%s est écorché-e vif.",
  "%s est pendu-e par les pieds, suspendu-e en haut d'une poulie et "
 ."précipité-e sur les dalles de la place.",
  "La tête de %s explose comme un fruit mur sous les coups de gourdins.",
  "%s est pendu haut et court." ]; # the killed player

$messages{'deads'}{'werewol_u_kill'} = 
[ "Vous vous êtes méchamment déléctés de la chair de %s.",
  "Vous avez saigné %s comme un porc !",
  "%s est tombé sous vos crocs.",
  "%s a succombé à votre appétit.",
  "Vous avez été sans pitié pour %s.",
  "Vous avez sucé %s jusqu'à la moelle.",
  "%s était fort délicieux.",
  "Il ne reste plus rien de %s." ]; # the dead player

$messages{'deads'}{'werewol_die_hunger'} = 
[ "Les loups-garous n'ont tué personne, et ils meurent tous de faim !" ];

$messages{'deads'}{'morning_no_dead'} = 
[ "Bonne nouvelle ! Tous les villageois sont vivants ce matin.",
  "On dirait que les loups-garous ne savent pas se servir de leurs dents.",
  "Gloire aux villageois qui passent une nuit sans aucune victime.",
  "Nos loups-garous se seraient-ils égarés en cherchant le Petit "
 ."Chaperon Rouge ?",

  "Oyez-oyez ! Personne ne manque à l'appel ce matin.\n"
 ."Mais qu'ont fait les loups-garous ?\n"
 ."Ils ont passé la nuit à picoler ou quoi ?" ];

$messages{'deads'}{'morning_one_dead'} = 
[ "Bonjour tout le monde, bien dormi ?\n"
 ."Je suppose, sauf pour l'un d'entre vous qui ne se réveillera pas.",
  "Le jour se lève sur le village…\n"
 ."…une nouvelle victime ne se réveillera pas.",
  "Villageois, les loups-garous ont encore frappé.",
  "Ce matin, une aube timide réveille le village.\n"
 ."Mais une malheureuse victime restera plongée dans un sommeil éternel.",
  "Ce matin, notre village est privé d'un de ses citoyens.\n"
 ."Un villageois a passé l'arme à gauche.",
  "Le soleil à la couleur du sang ce matin.\n"
 ."Un villageois est tombé aux pattes poilues des loups-garous.",
  "L'aube se lève sur le village de Thiercelieux.\n"
 ."Mais le clocher de l'église joue le glas de la mort.",
  "Pour ce matin, il y aura un café en moins à préparer.\n"
 ."Ça en fera plus pour les autres qui auront besoin d'être éveillés.",
  "Un jour rouge se lève : le sang a coulé cette nuit.",
  "Hep croquemort ! Une caisse pour le village, une !",
  "Villageois naïfs ! Pendant que vous dormiez, le pire est arrivé.",
  "Comptez-vous mourir un par un sans réagir, villageois ?",
  "La Grande Faucheuse est passée par le village et les villageois "
 ."l'ont bêtement laissé passer.",
  "On dirait qu'il ne fait pas bon confier sa vie à un de ces villageois.",
  "Cette nuit, un villageois s'est fait saigner comme un cochon !",
  "Nuit lunaire, matin mortuaire.\n"
 ."Un villageois manque déjà à ses amis." ];

$messages{'deads'}{'morning_two_deads'} = 
[ "Ce matin, rubrique nécrologique : deux braves citoyens nous ont quitté.",
  "Deux disparus à signaler ce matin.",
  "Ce matin, nous déplorons la perte de deux camarades.",
  "Deux des nôtres nous ont quitté ce jour.",
  "Un réveil dans l'horreur pour les villageois : deux cadavres gisent sur "
 ."le sol, ou ce qu'il en reste.",
  "La nuit aura coûté cher à deux villageois au sommeil lourd.",
  "Les villageois se réveillent dans une mare de sang.",
  "Au réveil, deux lits sont vides !",
  "Une seule nuit et déjà deux pertes chez les villageois.",
  "Villageois, ça craint pour vous ! Déjà deux tombes à creuser.",
  "C'est l'hécatombe. Deux personnes ne sont plus des nôtres." ];

$messages{'deads'}{'werevolves_kill'} = 
[ "Les loups-garous n'ont fait qu'une bouchée de %s.",
  "%s a été la victime des loups-garous.",
  "%s s'est fait-e dévorer comme un ptit pain.",
  "Les loups-garous rapportent que %s fut un peu filandreux-se "
 ."mais gouteux-se malgré tout.",
  "%s n'était que fort peu appétissant-e mais il faut bien manger.",
  "Tiens une tête par terre ! Mais c'est celle de %s !",
  "La place du marché est recouverte du sang de %s !",
  "%s n'a pas résisté à l'assaut des loups-garous.",
  "Nous n'avons retrouvé de %s que quelques poils épais "
 ."dans une flaque de sang." ]; # the killed player

$messages{'deads'}{'last_werewolf_kill'} = 
[ "Le dernier loup-garou se retourne vers %s et n'en fait qu'une bouchée.",
  "*Squiq* - Le sang de %s coule sous le regard du dernier loup-garou.",
  "%s se retrouve seul-e face au dernier loup-garou… "
 ."et n'offre aucune résistance." ]; # the killed player

$messages{'deads'}{'last_werewolves_kill'} = 
[ "Les derniers loups-garous se retournent vers %s et se le partagent.",
  "*Squiq* - Le sang de %s coule sous le regard des derniers loups-garous.",
  "Les loups-garous ricanent en se jetant férocement sur le dernier "
 ."villageois.",
  "Le dernier villageois ne peut rien faire et meurt héroïquement sous "
 ."les dents des loups-garous.",
  "Les loups-garous se découvrent enfin pour déchirer les chairs du dernier "
 ."villageois.",
  "Dans un hurlement d'agonie, le dernier villageois meurt dans d'atroces "
 ."souffrances.",
  "Les loups-garous se jettent sur leur dernière victime et la dévorent "
 ."sans même la tuer.",
  "%s se retrouve seul-e face aux derniers loups-garous… "
 ."et n'offre aucune résistance." ]; # the killed player

###########
## Votes ##
###########
$messages{'votes'}{'no_teamvote'}{'all'} = 
[ "Vous ne pouvez pas donner votre voix à un membre de votre équipe." ];

$messages{'votes'}{'no_teamvote'}{'for'} = 
[ "Vous pouvez pas voter pour vos pairs.",
  "Il est interdit de voter pour son équipe." ];

$messages{'votes'}{'no_teamvote'}{'against'} = 
[ "Vous pouvez pas voter contre vos pairs.",
  "Il est interdit de voter contre son équipe." ];

$messages{'votes'}{'vote'}{'all'} = 
[ "Vous avez choisi %s." ]; # the player you voted for or against

$messages{'votes'}{'vote'}{'for'} = 
[ "Vous avez voté pour %s.",
  "Votre voix va pour %s." ]; # the player you voted for

$messages{'votes'}{'vote'}{'against'} = 
[ "Vous avez voté contre %s.",
  "Votre voix va contre %s." ]; # the player you voted against

$messages{'votes'}{'change_vote'}{'all'} = 
[ "Vous aviez choisi %s, mais vous jetez votre dévolu sur %s." ]; # old vote, new vote for or against

$messages{'votes'}{'change_vote'}{'for'} = 
[ "Vous avez changé votre vote pour %s en faveur de %s.",
  "Vous aviez donné votre voix à %s, mais vous changez d'avis pour %s." ]; # old vote, new vote for

$messages{'votes'}{'change_vote'}{'against'} = 
[ "Vous avez changé votre vote à l'encontre de %s vers %s.",
  "Vous aviez donné votre voix contre %s, mais vous changez d'avis pour %s." ]; # old vote, new vote against

$messages{'votes'}{'equal_voices'}{'all'} = 
[ "%s ont le même nombre de voix.",
  "%s sont au coude-à-coude !",
  "%s ont autant de voix.",
  "%s sont tous autant pointés du doigt les uns que les autres." ]; # comma separated players with equal voices for or against

$messages{'votes'}{'equal_voices'}{'for'} = 
[ "%s sont autant approuvés les uns que les autres." ]; # comma separated players with equal voices for

$messages{'votes'}{'equal_voices'}{'against'} = 
[ "%s sont autant menacés les uns que les autres." ]; # comma separated players with equal voices against

$messages{'votes'}{'silent_player'}{'all'} = 
[ "%s est l'unique à ne pas s'être prononcé-e.",
  "Il ne reste que %s pour conclure le vote.",
  "Nous attendons le vote de %s.",
  "%s s'abstient toujours.",
  "%s n'a pas encore pris part au vote." ]; # the player who have not voted for or against yet

$messages{'votes'}{'silent_player'}{'for'} = 
[ "%s ne sait toujours pas pour qui voter." ]; # the player who have not voted for yet

$messages{'votes'}{'silent_player'}{'against'} = 
[ "%s ne sait toujours pas contre qui voter." ]; # the player who have not voted against yet

$messages{'votes'}{'silent_players'}{'all'} = 
[ "%s n'ont pas encore voté.",
  "%s ne se sont pas décidés.",
  "Le choix de %s n'est pas encore déterminé.",
  "%s ne se sont pas encore prononcés.",
  "%s s'abstiennent toujours.",
  "%s n'ont pas encore pris part au vote." ]; # comma separated players who have not voted yet

$messages{'votes'}{'silent_players'}{'for'} = 
[ "%s ne savent toujours pas pour qui voter." ]; # comma separated players who have not voted yet

$messages{'votes'}{'silent_players'}{'against'} = 
[ "%s ne savent toujours pas contre qui voter." ]; # comma separated players who have not voted yet

$messages{'votes'}{'status_votes'}{'all'} = 
[ "%s ont donné leur voix à %s." ]; # comma separated list of players who voted for or against, the targetted player

$messages{'votes'}{'status_votes'}{'for'} = 
[ "%s ont votés pour %s.",
  "%s sont en faveur de %s." ]; # comma separated list of players who voted for, the targetted player

$messages{'votes'}{'status_votes'}{'against'} = 
[ "%s ont une dent contre %s.",
  "%s en veulent à %s.",
  "%s maudissent %s.",
  "%s sont contre %s." ]; # comma separated list of players who voted against, the targetted player

$messages{'votes'}{'status_vote'}{'all'} = 
[ "%s a donné sa voix à %s." ]; # the player who voted for or against, the targetted player

$messages{'votes'}{'status_vote'}{'for'} = 
[ "%s a voté pour %s.",
  "%s est en faveur de %s." ]; # the player who voted for, the targetted player

$messages{'votes'}{'status_vote'}{'against'} = 
[ "%s a voté contre %s.",
  "%s a une dent contre %s.",
  "%s en veut à %s.",
  "%s maudit %s.",
  "%s est contre %s." ]; # the player who voted against, the targetted player

$messages{'votes'}{'nobody_voted'}{'all'} = 
[ "Personne n'a encore voté." ];

$messages{'votes'}{'nobody_voted'}{'for'} = 
[ "Personne n'a voté pour quiconque." ];

$messages{'votes'}{'nobody_voted'}{'against'} = 
[ "Personne n'en veut à quiconque.",
  "Tout le monde se regarde du coin de l'œil, mais personne ne vote." ];

################
##  Commands  ##
################
## help
$messages{'cmds'}{'help'}{'descr'} = 
 "Donne l'aide sur une ou toutes les commandes"; # (One line length)

$messages{'cmds'}{'help'}{'params'} = 
 "[commande]"; # (One line length)

$messages{'cmds'}{'help'}{'admin_commands'} = 
 "Commandes d'administrateurs : %s"; # the list of the admin commands

$messages{'cmds'}{'help'}{'moder_commands'} = 
 "Commandes des modérateurs : %s"; # the list of the moderator commands

$messages{'cmds'}{'help'}{'game_commands'} = 
 "Commandes à faire pendant le jeu : %s"; # the list of the game commands

$messages{'cmds'}{'help'}{'out_game_commands'} = 
 "Autres : %s"; # the list of the out of the game commands

$messages{'cmds'}{'help'}{'specific'} = 
 "Tapez \\chelp <commande> pour obtenir une aide spécifique à <commande>."; # the command char prefix

$messages{'cmds'}{'help'}{'usage'} = 
 "Usage : %s"; # the usage

## start
$messages{'cmds'}{'start'}{'descr'} = 
 "Lance une nouvelle partie"; # (One line length)

$messages{'cmds'}{'start'}{'run_already'} = 
[ "Une partie est déjà en cours." ];

$messages{'cmds'}{'start'}{'cannot_join'} = 
[ "Je tente de rejoindre %s car je n'y suis pas encore… Relancez \\cstart "
 ."quand j'y serais."]; # the night channel, the command prefix

$messages{'cmds'}{'start'}{'cannot_join_hidden'} = 
[ "Je tente de rejoindre un autre salon de nuit… Relancez \\cstart "
 ."quand j'y serais."]; # the command prefix

$messages{'cmds'}{'start'}{'not_op'} = 
[ "Je dois être opérateur sur %s et %s pour lancer une partie." ]; # the day channel, the night channel

$messages{'cmds'}{'start'}{'not_op_hidden'} = 
[ "Je dois être opérateur sur %s et le salon de nuit pour lancer une partie." ]; # the day channel

$messages{'cmds'}{'start'}{'no_werewolves'} = 
[ "Impossible de lancer une nouvelle partie :\n"
 ."Pour n'avoir qu'un loup-garou, il faut au moins %s joueurs." ]; # the minimum number of players

$messages{'cmds'}{'start'}{'new_game'} = 
[ "%s lance une nouvelle partie.",
  "Gloire à %s qui lance une nouvelle partie :)",
  "Merci %s, c'est parti.",
  "Que tout le monde se réveille, une partie va commencer !",
  "%s a décidé de chasser le loup ! Qui l'accompagnera dans cette expédition ?",
  "%s ne manque pas de cran et décide de lancer une partie.",
  "%s a décidé qu'il était temps de se faire une nouvelle partie." ]; # game caller

$messages{'cmds'}{'start'}{'your_card'} = 
[ "Votre carte est : %s.",
  "Vous êtes %s." ]; # the card

$messages{'cmds'}{'start'}{'num_werewolf'} = 
[ "Un des %i innocents villageois est un loup-garou !",
  "Il y a un traître parmi les %i villageois.",
  "Le seul loup-garou saura-t-il se cacher parmi les %i joueurs ?",
  "Villageois, un loup-garou se cache parmi vous %i !" ]; # the number of players

$messages{'cmds'}{'start'}{'num_werewolves'} = 
[ "%i des %i innocents villageois sont des loups garous !",
  "Il y a %i traîtres parmi les %i villageois.",
  "Villageois, %i loups garous se cachent parmi vous !",
  "Les %i loups-garous sauront-ils se cacher parmi les %i joueurs ?" ];
# werewolves number, players number

## stop
$messages{'cmds'}{'stop'}{'descr'} = 
 "Stoppe une partie en cours"; # (One line length)

$messages{'cmds'}{'stop'}{'already_stop'} = 
[ "Il n'y a aucune partie à arrêter…" ];

$messages{'cmds'}{'stop'}{'game_stopped'} = 
[ "Partie stoppée par %s :(",
  "Maudit soit %s d'avoir arrêté la partie !",
  "C'est fini, %s a stoppé la partie…" ]; # game stopper

## settimeout
$messages{'cmds'}{'settimeout'}{'descr'} = 
 "Change le temps maximal d'attente des phases du jeu"; # (One line length)

$messages{'cmds'}{'settimeout'}{'params'} = 
 "<phase> <seconde-s>";

$messages{'cmds'}{'settimeout'}{'example'} = 
[ "voyante 30",
  "cupidon 42" ];

$messages{'cmds'}{'settimeout'}{'timeout_set'} = 
[ "Temps d'attente maximal pour %s mis à %i seconde-s." ]; # the phase, the timeout

## showtimeouts
$messages{'cmds'}{'showtimeouts'}{'descr'} = 
 "Affiche les temps maximaux d'attente des phases"; # (One line length)

$messages{'cmds'}{'showtimeouts'}{'timeouts'} = 
 "Temps actuels : %s."; # comma separated list of the timeouts (in secs)

## setcards
$messages{'cmds'}{'setcards'}{'descr'} = 
 "Choisit quelle cartes spéciales utiliser"; # (One line length)

$messages{'cmds'}{'setcards'}{'params'} = 
 "( (add|del) <carte>  |  style <style>  |  nostyle )";

$messages{'cmds'}{'setcards'}{'example'} = 
[ "add sorcière",
  "style classic",
  "del chasseur" ];

$messages{'cmds'}{'setcards'}{'wrong_act'} = 
[ "Vous pouvez ajouter (add) ou retirer (del) des cartes, "
 ."me faire utiliser ou pas un style, mais pas '%s'." ]; # the wrong action

$messages{'cmds'}{'setcards'}{'need_card'} = 
[ "Vous devez spécifier une carte." ];

$messages{'cmds'}{'setcards'}{'need_style'} = 
[ "Vous devez spécifier un style." ];

$messages{'cmds'}{'setcards'}{'already_set'} = 
[ "%s est déjà ajouté-e." ]; # the already added card

$messages{'cmds'}{'setcards'}{'already_unset'} = 
[ "%s est déjà retiré-e." ]; # the already removed card

$messages{'cmds'}{'setcards'}{'card_set'} = 
[ "Nous jouerons désormais avec %s." ]; # the card which have been set

$messages{'cmds'}{'setcards'}{'card_set_but_style'} = 
[ "J'ajoute %s (mais le style %s reste activé)." ]; # the card which have been set, the current used style

$messages{'cmds'}{'setcards'}{'card_unset'} = 
[ "Nous ne jouerons plus avec %s." ]; # the card which have been unset

$messages{'cmds'}{'setcards'}{'card_unset_but_style'} = 
[ "Je retire %s (mais le style %s reste activé)." ]; # the card which have been unset, the current used style

$messages{'cmds'}{'setcards'}{'nostyle_set'} = 
[ "Nous utiliserons maintenant la liste manuelle de cartes." ];

$messages{'cmds'}{'setcards'}{'already_nostyle'} = 
[ "Je n'utilise déjà pas de style." ];

$messages{'cmds'}{'setcards'}{'style'} = 
[ "Nous utiliserons désormais le style %s." ]; # the just set style

$messages{'cmds'}{'setcards'}{'no_such_style'} = 
[ "Je ne connais pas le style %s." ]; # the not found style

## showcards
$messages{'cmds'}{'showcards'}{'descr'} = 
 "Affiche les cartes spéciales utilisées"; # (One line length)

$messages{'cmds'}{'showcards'}{'wrong_param'} = 
[ "Je ne sais pas quoi faire de votre paramètre '%s'." ]; # the wrong param

$messages{'cmds'}{'showcards'}{'cards_set'} = 
 "Cartes manuellement mises : %s."; # the comma separated list of the set cards

$messages{'cmds'}{'showcards'}{'cards_used'} = 
 "Cartes spéciales utilisées : %s."; # the comma separated list of the used cards

$messages{'cmds'}{'showcards'}{'cards_unused'} = 
 "Autres disponibles : %s."; # the comma separated list of the unused cards

$messages{'cmds'}{'showcards'}{'no_cards'} = 
[ "Aucune carte spéciale n'est utilisée." ];

$messages{'cmds'}{'showcards'}{'all_cards_used'} = 
[ "Toutes les cartes spéciales sont utilisées." ];

$messages{'cmds'}{'showcards'}{'style'} = 
[ "Distribution des cartes gérée par le style %s." ]; # the used style

$messages{'cmds'}{'showcards'}{'nostyle'} = 
[ "Nous n'utilisons pas de style en ce moment." ];

## showstyle
$messages{'cmds'}{'showstyle'}{'descr'} = 
 "Affiche la liste des styles de distribution de cartes, ou bien les détails d'un style."; # (One line length)

$messages{'cmds'}{'showstyle'}{'params'} = 
 "[<style>]";

$messages{'cmds'}{'showstyle'}{'all_styles'} = 
[ "Styles de distribution disponibles : %s." ]; # comma separated list of the style

$messages{'cmds'}{'showstyle'}{'no_such_style'} = 
[ "Le style '%s' n'existe pas. Tapez \\cshowstyle pour obtenir la liste des styles disponibles." ]; # the inexistant style

$messages{'cmds'}{'showstyle'}{'style_with_ply_limit'} = 
[ "Style de distribution %s (nombre de joueurs nécessaire: %s) :" ]; # the style name, the style players limits

$messages{'cmds'}{'showstyle'}{'style'} = 
[ "Style de distribution %s :" ]; # the sytle name

$messages{'cmds'}{'showstyle'}{'no_jobs'} = 
[ "Aucune carte spéciale distribuée." ];

$messages{'cmds'}{'showstyle'}{'job_always'} = 
 "toujours";

## tutorial
$messages{'cmds'}{'tutorial'}{'descr'} = 
 "Me dit de vous aider ou pas."; # (One line length)

$messages{'cmds'}{'tutorial'}{'tut_is_on'} = 
[ "Le mode tutoriel est actuellement activé pour vous." ];

$messages{'cmds'}{'tutorial'}{'tut_is_off'} = 
[ "Le mode tutoriel est actuellement désactivé pour vous." ];

$messages{'cmds'}{'tutorial'}{'tut_set_on'} = 
[ "Mode tutoriel activé." ];

$messages{'cmds'}{'tutorial'}{'tut_set_off'} = 
[ "Mode tutoriel désactivé." ];

$messages{'cmds'}{'tutorial'}{'tut_already_on'} = 
[ "Le mode tutoriel est déjà activé pour vous." ];

$messages{'cmds'}{'tutorial'}{'tut_already_off'} = 
[ "Le mode tutoriel est déjà désactivé pour vous." ];

$messages{'cmds'}{'tutorial'}{'wrong_param'} = 
[ "Vous pouvez mettre le mode tutoriel à 'on' ou 'off', mais pas à '%s'." ]; # the wrong param

## vote
$messages{'cmds'}{'vote'}{'descr'} = 
 "Indique votre intention de vote pour un joueur (souvent pour le tuer)."; # (One line length)

$messages{'cmds'}{'vote'}{'params'} = 
 "<quelqu'un>";

$messages{'cmds'}{'vote'}{'example'} = 
[ "Tartempion",
  "untel",
  "Mimamo",
  "Bliblu",
  "Villageois",
  "Clampin",
  "Teubé", 
  "Zayrow",
  "JeSuisCon" ];

## unvote
$messages{'cmds'}{'unvote'}{'descr'} = 
 "Annule votre vote."; # (One line length)

$messages{'cmds'}{'unvote'}{'no_vote'} = 
[ "Vous n'avez pas encore voté." ];

$messages{'cmds'}{'unvote'}{'vote_canceled'} = 
[ "Votre vote est maintenant annulé." ];

## choose
$messages{'cmds'}{'choose'}{'descr'} = 
 "Me dit quelle carte vous voulez voler (utilisé par le voleur)."; # (One line length)

$messages{'cmds'}{'choose'}{'intro'} = 
[ "Voleur, c'est votre tour.\nTapez \\cchoose 1 pour choisir la première carte, "
 ." \\cchoose 2 pour la deuxième, ou \\cchoose no pour devenir un simple "
 ."villageois." ]; # the command char prefix (3 times)

## play
$messages{'cmds'}{'play'}{'descr'} = 
 "M'indique dit que vous voulez jouer."; # (One line length)

$messages{'cmds'}{'play'}{'already_play'} = 
[ "Vous jouez déjà.",
  "Patience, attendez les autres joueurs.",
  "Tout le monde n'est pas encore prêt." ];

$messages{'cmds'}{'play'}{'now_play'} = 
[ "Bienvenue dans la partie.",
  "Votre destin est scellé.",
  "Vous assumerez l'entière responsabilité de cet engagement.",
  "Puisse votre courage vous faire survivre dans cette épreuve." ];

## unplay
$messages{'cmds'}{'unplay'}{'descr'} = 
 "Annule votre participation à un jeu."; # (One line length)

$messages{'cmds'}{'unplay'}{'no_play'} = 
[ "Vous ne jouez pas encore." ];

$messages{'cmds'}{'unplay'}{'play_canceled'} = 
[ "Vous ne jouerez plus.",
  "Vous partez honteusement de cette partie.",
  "Vous abandonnez une partie qui pourrait s'avérer interessante !",
  "Vous désertez piètrement le jeu… Auriez vous peur ?!",
  "Vous vous désistez lamentablement… Vous avouriez-vous déjà vaincu-e ?!",
  "Vous renoncez piteusement à cette partie." ];

## votestatus
$messages{'cmds'}{'votestatus'}{'descr'} = 
 "Affiche les votes en cours."; # (One line length)

## ident
$messages{'cmds'}{'ident'}{'descr'} = 
 "Me fait me identifier quelqu'un, probablement vous."; # (One line length)

$messages{'cmds'}{'ident'}{'params'} = 
 "[joueur mal connu]";

$messages{'cmds'}{'ident'}{'example'} = 
[ "joe_" ];

$messages{'cmds'}{'ident'}{'need_moder'} = 
[ "Vous devez être modérateur pour pouvoir me faire identifier quelqu'un "
 ."d'autre que vous." ];

## hlme
$messages{'cmds'}{'hlme'}{'descr'} = 
 "Me dit de vous appeler (ou pas) lorsque quelqu'un lance une partie, "
."et jusqu'à quand le faire."; # (One line length)

$messages{'cmds'}{'hlme'}{'wrong_param'} = 
[ "Je peux vous appeller jusqu'à ce que vous quittiez (quit), "
 ."que vous jouiez une partie (game), à chaque fois (forever) "
 ."ou jamais (never). Mais pas %s !" ]; # the wrong param

$messages{'cmds'}{'hlme'}{'hl'} = 
[ "Hého %s, une partie va commencer !",
  "%s va probablement nous rejoindre.",
  "%s sera certainement de la partie.",
  "%s m'a demandé de l'appeller." ]; # the hl'ed player

$messages{'cmds'}{'hlme'}{'hls'} = 
[ "Hého %s, une partie va commencer !",
  "%s vont probablement nous rejoindre.",
  "%s seront certainement de la partie.",
  "%s m'ont demandé de les prévenir." ]; # a comma separated list of hl'ed players

$messages{'cmds'}{'hlme'}{'forever'} = 
[ "Je vous appellerai à chaque lancement de partie." ];

$messages{'cmds'}{'hlme'}{'quit'} = 
[ "Je vous appellerai jusqu'à ce que vous quittiez le salon." ];

$messages{'cmds'}{'hlme'}{'game'} = 
[ "Je vous appellerai jusqu'à ce que vous jouiez une partie." ];

$messages{'cmds'}{'hlme'}{'never'} = 
[ "Je ne vous appellerai jamais." ];

## commands helps
$messages{'cmds'}{'helps'}{'show_choices'} = 
[ "Choix possibles : %s." ]; # comma separated choices

$messages{'cmds'}{'helps'}{'show_params'} = 
[ "Dites-moi ce que vous voulez en tapant %s.",
  "Indiquez-moi votre souhait en tapant %s.",
  "Dites-moi quoi faire en tapant %s.",
  "Indiquez-moi votre choix en tapant %s." ]; # the command and its params

$messages{'cmds'}{'helps'}{'show_example'} = 
[ "Exemple : %s" ]; # the command example

## talkserv
$messages{'cmds'}{'talkserv'}{'descr'} = 
 "Me fait dire quelque chose à un service."; # (One line length)

$messages{'cmds'}{'talkserv'}{'params'} = 
 "<service> <message>";

$messages{'cmds'}{'talkserv'}{'example'} = 
[ "nick REGISTER hoppop truc\@bidule.com",
  "nick GHOST foo hoppop",
  "chan REGISTER #village" ];

$messages{'cmds'}{'talkserv'}{'no_such_serv'} = 
[ "Je ne connais pas le service de '%s' !\n"
 ."Vous devez me le spécifier dans le fichier de configuration." ]; # the unknown service

## reloadconf
$messages{'cmds'}{'reloadconf'}{'descr'} = 
 "Me fait relire mon fichier de configuration."; # (One line length)

$messages{'cmds'}{'reloadconf'}{'error'} = 
[ "Une erreur est survenue pendant le chargement de %s :" ]; # the config file name

$messages{'cmds'}{'reloadconf'}{'reloaded'} = 
[ "Fichier de configuration %s relu avec succès." ];

## activate
$messages{'cmds'}{'activate'}{'descr'} = 
 "M'active."; # (One line length)

$messages{'cmds'}{'activate'}{'now_active'} = 
[ "Je suis maintenant activé." ];

$messages{'cmds'}{'activate'}{'already_active'} = 
[ "Je suis déjà activé." ];

## deactivate
$messages{'cmds'}{'deactivate'}{'descr'} = 
 "Me désactive."; # (One line length)

$messages{'cmds'}{'deactivate'}{'now_noactive'} = 
[ "Je suis maintenant désactivé." ];


#####################
##  Phase changes  ##
#####################
$messages{'time_to'}{'village_sleep'} = 
[ "Le village s'endort…",
  "Les villageois s'endorment paisiblement.",
  "Les villageois vont naïvement se coucher.",
  "Les innocents villageois vont au lit.",
  "La nuit tombante appelle les villageois à aller dormir.\nBonne nuit…",
  "Il est l'heure d'aller au lit les villageois, dormez tranquillement.",
  "Les fainéants de villageois choisissent de dormir plutôt que "
 ."de réfléchir plus longtemps.",
  "Quelqu'un aurait-il versé un somnifère ? Les villageois s'écroulent "
 ."soudainement de fatigue.\nBonne nuit…",
  "Chacun des villageois s'en retourne dans sa maisonnée et s'endort." ];

$messages{'time_to'}{'werewolves_kill'} = 
[ "Loups-garous, c'est l'heure de manger.",
  "À table les loups garous !",
  "Votre festin vous attend naïvement dans son lit.",
  "Votre victime dort paisiblement, elle n'attend plus que vous.",
  "Loups-garous, vous pouvez d'ores et déjà vous lécher les babines." ];

$messages{'time_to'}{'find_werewolves'} = 
[ "Il est temps de trouver un coupable !",
  "C'est le moment de repérer un loup-garou.",
  "Villageois, il faut trouver les traîtres.",
  "Quelqu'un doit mourir aujourd'hui !",
  "Quelqu'un doit payer pour ce crime ! Même s'il est innocent.",
  "Villageois, des traîtres continuent de vous trahir." ];

$messages{'time_to'}{'play'} = 
[ "Rappel de l'url des règles du salon : http://thiercelieux.fr/regles.html\n%s vont affronter leurs talents persuasifs dans cette partie.",
  "N'oubliez pas de lire les règles... http://thiercelieux.fr/regles.html\n%s, préparez vous mentalement à cette épreuve !",
  "Prêts à jouer ? Lisez les règles d'abord ! http://thiercelieux.fr/regles.html\n%s, une dure partie va commencer.",
  "Avant de vous plonger dans cette partie, lisez les règles : http://thiercelieux.fr/regles.html !\n%s, une passionnante partie est sur le point de commencer !" ]; # comma separated list of players


########################
##  Welcome messages  ##
########################
$messages{'welcome'}{'welcome'} = 
[ "Bienvenue sur %s ! Je suis le maître de jeu, et vous pouvez communiquer "
 ."avec moi (en privé, ou pas) à l'aide de commandes (\\chelp pour en avoir la "
 ."liste).\nMerci de prendre connaissance des règles du salon : "
 ."http://thiercelieux.fr/regles.html" ];

$messages{'welcome'}{'wait_game_end'} = 
[ "Pour l'instant, une partie est en cours. Vous devez donc attendre qu'elle "
 ."soit finie, puis vous pourrez parler et participer." ];

$messages{'welcome'}{'wait_game_start'} = 
[ "Aucune partie n'est en cours pour l'instant. Mais s'il y a assez de "
 ."participants, vous pouvez en lancer une en tapant \\cstart." ];

$messages{'welcome'}{'back'} = 
[ "%s est de retour dans la partie.",
  "%s reprend part au jeu." ];

$messages{'welcome'}{'back_new_nick'} = 
[ "%s (anciennement %s) est de retour dans la partie.",
  "%s (jadis %s) reprend part au jeu." ];
