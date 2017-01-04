# games.pl
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
##################################
# games configuration stuff

our (%files, %special_jobs);

# games.xml dump
our %games;

sub load_games_config_file {
    my $games_file = shift;
    my $games = 
    load_config_file($games_file, undef, games_conf_validator(),
		     ForceArray => [ 'style', 'job' ],
		     KeyAttr => { 'style' => 'name', 'job' => 'name' }
	);
    return 0 unless(defined($games));

    # Make it smaller
    $$games{'jobs'} = delete $$games{'jobs'}{'style'};

    # Loading succeeded, overwrite old config
    %games = %$games;
    $files{'games'} = $games_file;
    print "-> Loaded ".$games_file."\n";

    return 1;
}

sub games_conf_validator {
    my %games_validator =
    (
     'jobs' => {
	 'style' => {
	     '_type'    => 'str', # a style name
	     '_content' => {
		 'job' => {
		     '_type' => 'str', # a card name
		     '_content' => {
			 'num_players' => 'str' # ranges (-6 8 10-12 14-)
		     }
		 },
		 'num_players' => 'str' # ranges (-6 8 10-12 14-)
	     }
	 }
     }
    );
    return \%games_validator;
}

# Check if the number $n is in the $range (a \d?-\d? like string)
sub is_in_range {
    my ($n, $range) = @_;
    my ($min, $r, $max) = ($range =~ /(\d+)?(-)?(\d+)?/);
    
    return ($r && ( # n?-m? range
		    ($min && ($min <= $n) || !$min)
		    && ($max && ($n <= $max) || !$max)
	    )
	    || ( !$r && ($n == $min)) # single number
	);
}


# Fills %special_jobs as the jobs style says.
# Returns 0 if the style cannot be applied to the number of players,
# or 1 otherwise.
sub apply_jobs_style {
    my ($style, $num_players) = @_;
    my $cards = $games{'jobs'}{$style}{'job'};

    if(exists($games{'jobs'}{$style}{'num_players'})) {
	unless(is_in_range($num_players,
			   $games{'jobs'}{$style}{'num_players'})) {
	    return 0;
	}
    }

    # First reset all
    $special_jobs{$_}{'wanted'} = 0 foreach(keys(%special_jobs));

    foreach my $j (keys(%$cards)) {
	unless(exists($special_jobs{$j})) {
	    print "# warning: in job style \`$style': "
		."discarding unknown job \`$j'\n";
	    next;
	}

	# Without num_players="..." assume we always want this job
	unless(exists($cards->{$j}{'num_players'})) {
	    $special_jobs{$j}{'wanted'} = 1;
	    next;
	}

	foreach my $r (split(/ /, $cards->{$j}{'num_players'})) {
	    $special_jobs{$j}{'wanted'} = is_in_range($num_players, $r);
	    last if($special_jobs{$j}{'wanted'});
	}
    }
    return 1;
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1
