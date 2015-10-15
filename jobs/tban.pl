# tban.pl
# Copyright (C) 2010  Gilles Bedel
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

our (%CFG, %messages, %users, %chanusers, @tbans);

add_command('tban',
{
	'subaddr'    => \&cmd_tban,
	'min_args'   => 2,
	'need_admin' => 0,
	'need_moder' => 1,
	'game_cmd'   => 0
});

# We know we redefine these subs, that's intended
no warnings 'redefine';

sub real_user {
    my ($to, $nick, $prio) = @_;
    my @found;

    $nick =~ s/[^\[\]\\\`\{\|\}\^\-_[:alnum:]]//g;# delete forbidden nick chars
    foreach(keys(%users)) {
        return $nick if($_ eq $nick); # Well spelled
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

sub human_time_fr {
    my $secs = shift;
    my @divs = (60, 60, 24, 7, 1);
    my @divs_str = ("seconde", "minute", "heure", "jour", "semaine");
    my ($i, $n);
    my @str;

    for($i = 0; $i < @divs; $i++) {
        if($divs[$i] == 1) {
            $n = $secs;
        } else {
            $n = $secs % $divs[$i];
        }
        if($n) {
            push(@str, $n." ".$divs_str[$i].($n > 1 ? 's':''));
        }
        $secs = int($secs/$divs[$i]);
    }

    if(@str > 1) {
	$str[1] = $str[1]." et ".$str[0];
	shift(@str);
    }
    return join(', ', reverse(@str));
}

## tban command
sub cmd_tban {
    our $conn;
    my ($ni, $to, $t, $target, @reason) = @_;
    my (@targ_ni, $targ_mask);
    my $time = 0;
    my %units = (
	'm' => 60, 'h' => 60*60, 'j' => 60*60*24,
	's' => 60*60*24*7
    );

    unless($chanusers{$CFG{'day_channel'}}{$CFG{'nick'}}{'op'}) {
	say(P_ADMIN, 'error', $ni, $messages{'cmds'}{'tban'}{'need_op'}, $CFG{'day_channel'});
	return 1;
    }

    if($t !~ /^(([0-9]+)([mhjs]))+$/) {
	say(P_ADMIN, 'error', $ni, $messages{'cmds'}{'tban'}{'wrong_time'}, $t);
	return 1;
    }

    while($t =~ /([0-9]+)([mhjs])/g) {
	unless(exists($units{$2})) {
	    say(P_ADMIN, 'error', $ni, $messages{'cmds'}{'tban'}{'wrong_time'}, $t);
	    return 1;
	}
        $time += $1 * $units{$2};
	delete $units{$2};
    }

    if ($target =~ /(.+)!(.+)@(.+)/) {
	$targ_mask = $target;
        foreach(keys(%users)) {
            my $irc_ident = $_.'!'.$users{$_}{'ident'}{'user'}.'@'
              .$users{$_}{'ident'}{'host'};
            if(defined($users{$_}{'ident'}{'domain'})) {
                $irc_ident .= $users{$_}{'ident'}{'domain'};
            }

            my $str = $targ_mask;
            # build the regexp
            $str = quotemeta($str); # add backslashes metachars
            # replace backslashes by dots before quantifier '*'
            $str =~ s/\\(\*)/\.$1/g;
	    push(@targ_ni, $_) if($irc_ident =~ /$str/);
	}
#	unless(@targ_ni) {
#	    say(P_ADMIN, 'error', $ni, $messages{'cmds'}{'tban'}{'no_match_mask'}, $target, $CFG{'day_channel'});
#	    return 1;
#	}

    } else {
	$targ_ni[0] = real_user($ni, $target, P_ADMIN); # If poorly typed
	return 1 unless(defined($targ_ni[0])); # More than one player found
	unless(exists($chanusers{ $CFG{'day_channel'} }{$targ_ni[0]})) {
	    say(P_ADMIN, 'error', $ni, $messages{'cmds'}{'tban'}{'unknown_user'}, $targ_ni[0]);
	    return 1;
	}
	$targ_mask = '*!*@'.$users{$targ_ni[0]}{'ident'}{'host'};
	if(defined($users{$targ_ni[0]}{'ident'}{'domain'})) {
	    $targ_mask .= $users{$targ_ni[0]}{'ident'}{'domain'};
	}
    }

    if (@targ_ni) {
      print "-> Banning ".join(',', @targ_ni)." for $time seconds\n";
    } else {
      print "-> Banning mask $targ_mask for $time seconds\n";
    }
    $conn->mode($CFG{'day_channel'}, '+b', $targ_mask);
    my $reason;
    if(@reason) {
	$reason = "[par $ni, pour ".human_time_fr($time)."] ".join(' ', @reason);
    } else {
	$reason = "par $ni, pour ".human_time_fr($time);
    }
    $conn->kick($CFG{'day_channel'}, $_, $reason) foreach(@targ_ni);

    my %entry = ('end' => time() + $time, 'mask' => $targ_mask);
    push(@tbans, \%entry);
    add_timer($time, \&remove_pending_ban, $targ_mask, \%entry);
    return 1;
}

sub cmd_tban_remove_ban {
    our (%CFG, $conn);
    $conn->mode($CFG{'day_channel'}, '-b', $_[0]);
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1
