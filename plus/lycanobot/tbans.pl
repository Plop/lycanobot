# tbans.pl
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
##################################
# game settings stuff

our @tbans = ();

sub write_tbans {
    my %data = ('tban' => [ @tbans ]);
    return write_persistent_data(\%data, 'tbans',
				 RootName => 'tbans',
				 KeyAttr => 0);
}

sub read_tbans {
    our %files;

    my $data;
    my $filename = $files{'homedir'}.'/'.$files{'tbans'}{'name'};
    return 1 unless(-e $filename); # Not a fatal error

    $data = read_persistent_data('tbans', ForceArray => 1, KeyAttr => 0);
    return 0 unless(defined($data));

    if (exists($data->{'tban'})) {
	@tbans = @{$data->{'tban'}};
    } else {
	@tbans = ();
    }
    foreach(@tbans) {
	add_timer_at($_->{'end'}, \&remove_pending_ban, $_->{'mask'}, $_);
    }
    print "-> Loaded ".$filename." (".@tbans." pending ban(s))\n";
    return 1;
}

sub remove_pending_ban {
    our (%CFG, $conn, %chanusers);
    my ($mask, $ref) = @_;

    unless($chanusers{$CFG{'day_channel'}}{$CFG{'nick'}}{'op'}) {
	add_timer(5, \&remove_pending_ban, @_);
	return;
    }

    $conn->mode($CFG{'day_channel'}, '-b', $_[0]);

    foreach(0 .. $#tbans) {
	if($tbans[$_] eq $ref) {
	    splice(@tbans, $_, 1);
	}
    }
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1
