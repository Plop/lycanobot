# timer.pl
# Copyright (C) 2009  Gilles Bedel
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
# Timers

# Contains various timers ids, used in various places
our %timers =
(
 'deco_checker' => { # Bot connection checker
     'timer' => undef,
     'cping_timer' => undef
 }
);


# All the timers are ordered by their happening time.
my @timers = (
# { 'id' => 1, 'time' => 12345, 'code' => \&do_that, 'args' => [ "arg1", ...] },
# { 'id' => 2, 'time' => 12350, 'code' => \&and_that }
);
my $last_id;

# Adds a timer in the @timers queue, keeping its order.
# Unique arg is the hash you want to put in @timers.
sub place_timer {
    my $t = shift;

    my $tlen = $#timers;
    foreach my $i (0 .. $tlen) {
        if($timers[$i]->{'time'} > $t->{'time'}) {
	    @timers = ( @timers[0  .. $i-1], $t, @timers[$i .. $tlen] );
	    last;
	}
    }
    # The previous loop cannot put it at the end, test for such case
    push(@timers, $t) if($tlen == $#timers);
}

# Adds a $code to happen in $time. Returns the timer id.
sub add_timer {
    my ($offset, $code, @args) = @_;

    return add_timer_at($offset + time(), $code, @args);
}

# Adds a $code to happen at $time. Returns the timer id.
sub add_timer_at {
    my ($time, $code, @args) = @_;
    my $new_id = defined($last_id) ? $last_id + 1 : 0;

    my $t = {
        'id'   => $new_id,
        'time' => $time,
        'code' => $code,
	'args' => [ @args ]
    };
    # Place it in @timers so that our timers keeps ordered.
    place_timer($t);
    $last_id = $t->{id};
    return $t->{id};
}

# Remove timer by id. Returns the removed timer, or undef if not found.
sub remove_timer {
    my $id = shift;

    foreach(0 .. $#timers) {
	if($timers[$_]->{'id'} eq $id) {
	    return splice(@timers, $_, 1);
	}
    }
    return undef;
}

# Set a timer to happen later. Returns 1 on success, or undef on failure.
sub set_timer {
    my ($id, $offset) = @_;
    my $new_time = time()+$offset;
    my $timer = remove_timer($id);
    return undef unless(defined($timer));

    $timer->{'time'} = $new_time;
    place_timer($timer);
    return 1;
}

# Run timers. Unique arg is the current time.
sub check_timers {
    my $now = shift;

    while(@timers && $timers[0]->{'time'} <= $now) {
        my $t = shift(@timers);
        my @args;
        @args = @{$t->{'args'}} if(ref($t->{'args'}) eq 'ARRAY');
        $t->{'code'}->(@args) if(ref($t->{'code'}) eq 'CODE');
    }
}

# Get the remaining time of a running timer.
# Returns undef if the timer id was not found.
sub timer_remaining {
    my $id = shift;
    my ($timer) = grep { $_->{'id'} eq $id } @timers;
    if(defined($timer)) {
	return $timer->{'time'} - time();
    } else {
	return undef;
    }
}

sub update_last_IRC_recv {
    our %CFG;
    my $timeout = $CFG{'timeout'} - 10; # Our CTCP timeout is 10 seconds
    $timeout = 10 unless($timeout >= 10); # Keep a serious value

    if(defined($timers{'deco_checker'}{'timer'})) {
	set_timer($timers{'deco_checker'}{'timer'}, $timeout);
    } else {
	$timers{'deco_checker'}{'timer'} = add_timer($timeout, \&cping_us);
    }
}

sub cping_us {
    our %CFG;
    $timers{'deco_checker'}{'timer'} = undef;
    my $msg = cping($CFG{'nick'});
    $msg->{'also_do'} = sub {
	# Wait 10 secs for a reply, then reset the connection
	$timers{'deco_checker'}{'cping_timer'}
	  = add_timer_at($_[0] + 10, \&reconnect_IRC); # $_[0] == current time

    }
}

# Disconnect and reconnect to the IRC server.
sub reconnect_IRC {
    $timers{'deco_checker'}{'cping_timer'} = undef; # timer reached
    # If we disconnect first, Net::IRC die() saying there are no active
    # connections, so we reconnect first.
    our $conn;
    my $oldconn = $conn;
    connect_to_IRC_server();
    $oldconn->disconnect();
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1
