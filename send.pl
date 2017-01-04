# send.pl
# Copyright (C) 2008  Gilles Bedel
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
###############################
# All the needed stuff to send

our (%CFG);

### Rate control
# Messages waiting for being sent. Hash of array of hashes.
#
# This hash has one key for each possible message destination (channel or user)
# in a portable form (passed trought make_user_pnick()).
# The(se) key(s) refers to an array of hashes. These hashes include the
# following keys:
# 'type' => 'privmsg', 'notice', 'mode', 'invite', 'who', 'whois', 'raw','cping'
#           or the pseudo message 'do_sub'
# 'to'   => msg destination (channel or nick)
# 'data' => the text msg, mode string, or the channel where we invite,
#           or a ref to a sub to execute if 'type' eq 'do_sub'
# 'time' => the amount of time the message should block the send queue,
# 'prio' => the priority of the message (integer).
# 'also_do' => an optional coderef to execute when we send the message
#
# All the messages in a send queue are ordered by their priority. The higher a
# priority number is, the higher the message priority is. When a new message
# is put in a send queue, it's inserted in the array so that this order is kept.
#
# Here is an example :
# our $send_queue = {
#   make_user_pnick('#foo') =>
#     [ { 'type' => 'mode', 'to' => '#foo', 'txt' => '-v joe', 'time' => 1 } ]
#   make_user_pnick('joe')  => 
#     [ { 'type' => 'invite',  'to' => 'joe', 'txt' => '#foobar', 'time' => 1 },
#       { 'type' => 'privmsg', 'to' => 'joe', 'txt' => "Please join #foobar",
#         'time' => 2 } ]
# };
our %send_queue;

# The moment (given by time()) in which the next queued message will be sent.
# If the global_limit config option is true, there is 2 keys in it:
#   global: the next message time
# last_dst: the last destination (used to round-robin around %send_queue)
#
# Otherwise (global_limit falst), its keys are each possible message
# destination, just like %send_queue.
our %send_queue_time;

# Message priority settings. We have 3 main flags that set a message priority:
# ADMIN & GAME & ADVANCE = PRIO # message example
#     0 &    0 &       0 =    0 # !help reply
#     0 &    0 &       1 =    / 
#     0 &    1 &       0 =    2 # !votestatus reply
#     0 &    1 &       1 =    3 # !hunt, !start reply
#     1 &    0 &       0 =    4 # !reloadconf, !talkserv reply
#     1 &    0 &       1 =    /
#     1 &    1 &       0 =    5 # !setcards reply
#     1 &    1 &       1 =    6 # !stop reply

# ADVANCE is only meaningfull if GAME is set

# ADMIN and GAME flags are a bit specials, because :
# - If  ADMIN, then !GAME > GAME
# - If !ADMIN, then !GAME < GAME
#
# They must be AND'ed and bit-negated if not set, so that :
# GAME  = 011   #  GAME == 3
# ADMIN = 110   # ADMIN == 6
# -----------
# ~G&~A = 000
#  G&~A = 001
#  G& A = 010
# ~G& A = 100

#    PRIO_IRC_PROTO: For important IRC related messages (pings, whois, etc.)
#        PRIO_ADMIN: Message is about an administrative task
#         PRIO_GAME: Message is from inside a running game
#      PRIO_ADVANCE: Message makes the game advance 
#        PRIO_ERROR: error message (less important) (guessed by message class)
use constant PRIO_IRC_PROTO    => 32;   # 0100000

use constant PRIO_ADMGME_MASK  => 7<<2; # 0011100 ---AND mask
use constant PRIO_ADMIN        => 6<<2; # 0011000 \_ AND'ed
use constant PRIO_GAME         => 3<<2; # 0001100 /

use constant PRIO_ADVANCE      => 2;    # 0000010
use constant PRIO_NOERROR      => 1;    # 0000001 # info or reply or request
use constant PRIO_ERROR        => 0;    # 0000000 # error

# Shortcuts for commons prio
use constant P_GAME      => ( PRIO_GAME  & ~PRIO_ADMIN) & PRIO_ADMGME_MASK;
use constant P_GAMEADV   => ( P_GAME | PRIO_ADVANCE );
use constant P_ADMIN     => (~PRIO_GAME  &  PRIO_ADMIN) & PRIO_ADMGME_MASK;
use constant P_GAMEADMIN => ( PRIO_GAME  &  PRIO_ADMIN) & PRIO_ADMGME_MASK;

use Carp qw(cluck);

# Push a message on the send queue. Returns $msg.
sub push_on_sendqueue {
    my ($prio, $msg) = @_;
    my $queue;

    # Do not say anything unless active or IRC related message
    return unless(is_true($CFG{'active'}) || ($prio & PRIO_IRC_PROTO));

    # Backward compatibility check
    unless(defined($msg) && ref($msg) eq 'HASH') {
	cluck("# warning: old style args given to push_on_sendqueue(), ignoring");
	return;
    }
    $$msg{'to'} = make_user_pnick($$msg{'to'});

    $$msg{'prio'} = $prio;
    $queue = \$send_queue{ $$msg{'to'} };

    if(ref($$queue) eq 'ARRAY') {
	# Here, all the message in each send queue are ordered by priority.
	# All we need is to put our new one in the right place to keep it.
	my $qlen = $#$$queue;
	foreach my $i (0 .. $qlen) {
	    next if($$$queue[$i]->{'prio'} >= $prio);
	    
	    $$queue = [ @$$queue[0 .. $i-1],
			$msg,
			@$$queue[$i .. $qlen] ];
	    last;
	}
	# The previous loop cannot put it at the end, test for such case
	push(@$$queue, $msg) if($qlen == $#$$queue);

    } else {
	# No existing messages in this queue, create it
	$send_queue{ $$msg{'to'} } = [ $msg ];
    }
    return $msg;
}

# Check if there is some things to send, and delete the empty send queues.
# Arg 1: the current time (given by time())
# Returns an array of the messages we have to send.
sub check_send_queue {
    my $cur_time = shift;
    my $q = 'global';
    my $i = 0;

    foreach(keys(%send_queue)) {
	# Delete any empty send queue
	delete $send_queue{$_} unless(@{ $send_queue{$_} });
    }
    my @dsts = keys(%send_queue);

    if(is_true($CFG{'global_limit'})) {
	return (()) unless($send_queue_time{'global'} <= $cur_time);

	return (()) unless(@dsts); # No messages waiting

	# Search what messages have the higest prio
	my $highest = 0;
	foreach(@dsts) {
	    if($send_queue{$_}->[0]->{'prio'} > $highest) {
		$highest = $send_queue{$_}->[0]->{'prio'};
	    }
	}

	my @highests = grep {$send_queue{$_}->[0]->{'prio'} == $highest} @dsts;

	# Round robin around the destinations
	my $dst = $send_queue_time{'last_dst'};
	unless(defined($dst) && exists($send_queue{$dst})) {
	    $send_queue_time{'last_dst'} = $dst = $highests[0];
	}

	# First look who is the next destination, then if not found take the 1st
	my ($end, $found) = (0,0);
	while(!$end) {
	    $end = 1 if($found);
	    foreach(@highests) {
		if($found) {
		    $send_queue_time{'last_dst'} = $_;
		    return shift(@{ $send_queue{$_} });
		}
		$found++ if($_ eq $dst);
	    }
	    $found++;
	}
	return (());
    } else {
	my @to_send;
	foreach(@dsts) {
	    if(ref($send_queue{$_}) eq 'ARRAY' && @{ $send_queue{$_} }) {
		unless(exists($send_queue_time{$_})) {
		    # First message on this sendq, init its time
		    $send_queue_time{$_} = -1;
		}

		if($send_queue_time{$_} <= $cur_time) {
		    push(@to_send, shift(@{ $send_queue{$_} }));
		}
	    } else {
		delete $send_queue{$_};
	    }

	    if(exists($send_queue_time{$_})) {
		# No need to keep a send_queue_time if it's in the past
		if($send_queue_time{$_} < $cur_time) {
		    delete $send_queue_time{$_};
		}
	    }
	}
	return @to_send;
    }
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1
