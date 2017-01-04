# jobs.pl
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
######################################
# Jobs loading stuff

our (%special_jobs, %phases, %cmdlist);

# Arg 1: phase name
# Arg 2: (hashref) job description, using the following keys :
#  distribute : optionnal boolean, if the job is distributable at the beginning
#               of the game or not. Default: 1
#  wanted     : if we want it to be distributed or not. Default: 1
#  help       : a ref to the help message (sent if tutorial mode enabled)
#  data       : extra informations (a hash) we want to keep in the
#               %special_jobs hash when the game is running.
#  initsub    : a coderef executed at a game startup if we want the job
#  phases     : related phases, described just like the %phases hash does. They
#               are always loaded, even if the job is not wanted.
#  commands   : same as 'phases' but for the commands (stored %cmdlist).
sub add_job {
    our %game_sets;

    my ($name,$desc) = @_;
    my %job;
    my @unknown_keys;

    if(exists($special_jobs{$name})) {
	print "# error : couldn't add job \`$name': it is already added\n";
	return;
    }

    unless(ref($desc) eq 'HASH') {
	print "# error : couldn't add job \`$name' : description (2nd arg) must be a hash ref\n";
	return;
    }

    while(my ($k,$v) = each(%$desc)) {
	if($k eq 'data') {
	    $job{'_data'} = $v; # A default that will be reloaded for each game
	}
	if($k eq 'distribute') {
	    $job{$k} = is_true($v);
	} elsif($k eq 'data' || $k eq 'initsub') {
	    $job{$k} = $v;
	} elsif($k eq 'phases') {
	    while(my ($phs_name, $phs_desc) = each(%{ $$desc{'phases'} })) {
		add_phase($phs_name, $phs_desc);
	    }
	} elsif($k eq 'commands') {
	    while(my ($cmd_name, $cmd_desc) = each(%{ $$desc{'commands'} })) {
		add_command($cmd_name, $cmd_desc);
	    }
	} elsif($k eq 'votes') {
	    while(my ($vote_name, $vote_desc) = each(%{ $$desc{'votes'} })) {
		add_votephase($vote_name, $vote_desc);
	    }
	} else {
	    push(@unknown_keys, $k);
	}
    }
    if(@unknown_keys) {
	print "# warning : in job \`$name': ignored some unknown description key(s):\n#           ".join(', ',@unknown_keys)."\n";
    }

    $special_jobs{$name} = \%job;
    unless(exists($game_sets{'jobs'}{'wanted'}{$name})) {
	$game_sets{'jobs'}{'wanted'}{$name} = 0;
    }
}

# Adds a phase to the %phases hash
# Arg 1: phase name
# Arg 2: (hashref) phase description, using %phases keys.
sub add_phase {
    my ($name,$desc) = @_;
    my %phs;

    if(exists($phases{$name})) {
	print "# error : couldn't add phase \`$name': it is already added\n";
	return;
    }

    unless(ref($desc) eq 'HASH') {
	print "# error : couldn't add phase \`$name' : description (2nd arg) must be a hash ref\n";
	return;
    }

    while(my ($k,$v) = each(%$desc)) {
	if($k eq 'who' || $k eq 'presub' || $k eq 'postsub'
	   || $k eq 'timeoutsub' || $k eq 'next' || $k eq 'timeout_to') {
	    $phs{$k} = $v;
	} elsif($k eq 'hide_timeout') {
	    $phs{'hide_timeout'} = is_true($v);
	} else {
	    print "# warning : ignored unknown description key \`$k' in phase \`$name'\n";
	}
    }

    $phs{'nick'} = undef;
    $phases{$name} = \%phs;
}

# Adds a vote phase to the %votes hash
# Arg 1: phase name
# Arg 2: (hashref) phase description, using %votes keys.
sub add_votephase {
    our %votes;
    my ($name,$desc) = @_;
    my %phs;

    if(exists($votes{$name})) {
	print "# error : couldn't add vote phase \`$name': "
	    ."it is already added\n";
	return;
    }

    unless(ref($desc) eq 'HASH') {
	print "# error : couldn't add vote phase \`$name' : "
	    ."description (2nd arg) must be a hash ref\n";
	return;
    }

    while(my ($k,$v) = each(%$desc)) {
	if($k eq 'chan' || $k eq 'purpose' || $k eq 'endsub') {
	    $phs{$k} = $v;
	} elsif($k eq 'teamvote') {
	    $phs{'teamvote'} = is_true($v);
	} else {
	    print "# warning : ignored unknown description key \`$k' "
		."in vote phase \`$name'\n";
	}
    }

    # We set this flag to remember we must delete this command when the game
    # ends.
    $phs{'external'} = 1;
    $votes{$name} = \%phs;
}

# Adds a phase to the %cmdlist hash
# Arg 1: phase name
# Arg 2: (hashref) phase description, using %cmdlist keys.
sub add_command {
    our %messages;
    my ($name,$desc) = @_;
    my %cmd;

    if(exists($cmdlist{$name})) {
	print "# error : couldn't add command \`$name': it is already added\n";
	return;
    }

    unless(ref($desc) eq 'HASH') {
	print "# error : couldn't add command \`$name' : description (2nd arg) must be a hash ref\n";
	return;
    }

    # Check for mandatory keys
    foreach('subaddr', 'descr') {
	unless(exists($$desc{$_}) || exists($messages{'cmds'}{$name}{$_})) {
	    print "# error : command \`$name' desc lacks the '$_' key\n";
	    return;
	}
    }

    # We need a valid coderef
    unless(ref($$desc{'subaddr'}) eq 'CODE') {
	print "# error : command \`$name' subaddr isn't a code ref\n";
	return;
    }

    foreach('subaddr', 'descr', 'need_admin', 'need_moder', 'need_alive', 'to',
	    'from', 'phase', 'min_args', 'params', 'example', 'intro',
	    'game_cmd') {
	$cmd{$_} = delete $$desc{$_} if(exists($$desc{$_}));
    }
    foreach(keys(%$desc)) {
	print "# warning : ignored unknown description key \`$_' in command \`$name'\n";
    }

    # We set this flag to remember we must delete this command when the game
    # ends.
    $cmd{'external'} = 1;
    $cmdlist{$name} = \%cmd;

    # Prevent help keys from beeing added (cmd help messages are already set).
    cmd_lock_help_keys($name);
}

# Loads a messages file for a given job name. If not found, falls back to the
# first matching messages file for the job.
# Returns 1 on success, 0 otherwise (in which case an error message is printed)
sub load_job_lang {
    our (%CFG);
    my ($dir, $job) = @_;
    my $lang = $CFG{'language'};

    # Try to load the file for the current language
    if(-e "$dir/$job-$lang.pl") {
	return load_file("$dir/$job-$lang.pl", 'messages');
    }

    # Otherwise, try another existing language, if any
    opendir(J, $dir) or
      print "# error : couldn't parse the job messages directory \`$dir': $!\n",
      return 0;
    my @files = grep { /^[^.].+?-.+?\.pl$/ } readdir(J);
    close(J);

    foreach(@files) {
	if(/^\Q$job\E-(.+)\.pl$/) {
	    print "# warning: no $lang language file found for job `$job'. "
		."Using existing $1 instead.\n";
	    return load_file("$dir/$job-$1.pl", 'message');	    
	}
    }

    # Certainly an error, but go ahead anyway...
    print "# warning: no messages files found for job \`$job'.\n";
    return 1;
}

# Simply runs a file. Returns nothing.
# Returns 1 on success, 0 otherwise (in which case an error message is printed)
sub load_file {
    my ($file, $purpose) = @_;

    # Load the file
    unless (my $return = do $file) {
	if($@) {
	    print "# error : couldn't parse $purpose file $file: $@";
	} elsif(!defined($return)) {
	    print "# error : couldn't do $purpose file $file: $!\n";
	} elsif(!$return) {
	    print "# error : couldn't run $purpose file $file\n";
	}
	return 0;
    }
    return 1;
}

# Loads the jobs files
# Arg 1: jobs directory
# Returns 1 on success, 0 otherwise (in which case an error message is printed)
sub load_jobs {
    our (%CFG, %game_sets);
    my ($dir) = @_;
    my @files;
    my %jobs;
    my (@unknown_jobs, @unknown_phs);

    opendir(J, $dir) or print "# error : couldn't parse the jobs directory \`$dir': $!\n", return 0;
    @files = grep { /^[^.].+\.pl$/ } readdir(J);
    close(J);

    unless(@files) {
	print "# warning : no jobs (no .pl files) found in directory \`$dir'\n";
	return 1; # Not really an error
    }

    print "-> Loading jobs files:\n";
    foreach(@files) {
	print "  - $_\n";
	if(load_job_lang($dir.'/messages', $_ =~ /(.+)\.pl/)) {
	    load_file($dir.'/'.$_, 'job');
	}
	# If an error occured it has been already printed.
    }

    # Activate wanted jobs in the config file, and check if there are some
    # missing.
    foreach(keys(%{ $game_sets{'jobs'}{'wanted'} })) {
	unless(exists($special_jobs{$_})) {
	    push(@unknown_jobs, $_);
	}
    }
    if(@unknown_jobs) {
	print "# warning : some unknown jobs were in <wanted> in the settings file:\n";
	print "#           ".join(', ',@unknown_jobs)."\n";
    }

    # Same for the phases timeouts
    foreach(keys(%{ $game_sets{'timeouts'} })) {
	unless(exists($phases{$_})) {
	    push(@unknown_phs, $_);
	}
    }
    if(@unknown_phs) {
	print "# warning : some unknown phases were found in <timeouts> in the settings file:\n";
	print "#           ".join(', ',@unknown_phs)."\n";
    }

    print "-> Done\n";
    return 1;
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1


