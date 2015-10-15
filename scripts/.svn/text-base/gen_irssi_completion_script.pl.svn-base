#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;
use XML::Simple;
use POSIX qw(strftime);

our (%cmdlist, %CFG, %phases, %messages, %special_jobs, %games);

sub gen_header {
    my $date = strftime("%Y-%m-%d", localtime());
    return <<EOT;
# This file was automatically generated using the
# lycanobot gen_irssi_completion_script.pl's script.
# Some of its variables match the ones used on the
# lycanobot install this script was generated from.

use strict;
use vars qw(\$VERSION \%IRSSI);
use Irssi;

\$VERSION = '1.00';

\%IRSSI = (
    authors     => 'Gilles Bedel',
    contact     => 'rot13("tvyybh.enl\@serr.se")',
    name        => 'Lycanobot_tab_completion',
    description => 'Tab-completion commands for Lycanobot (for more info :'
                  .'http://fr.dotsec.net/index.php/Lycanobot).',
    license     => 'GPLv3+',
    url         => 'https://fr.dotsec.net/svn/lycanobot/trunk/irssi/gen_lycanobot_tab_completion.pl',
    changed     => '$date',
);

my \$cmd_prefix = '$CFG{cmd_prefix}';
my \@allowed_dst = ( '$CFG{day_channel}', '$CFG{night_channel}', '$CFG{nick}' );
EOT
}

sub include {
    my ($file) = @_;

    unless (my $return = do $file) {
        die "Couldn't parse $file: $@\n" if $@;
        die "Couldn't do $file: $!\n"    unless defined $return;
        die "Couldn't run $file\n"       unless $return;
    }
}

sub load_only_jobs {
    my ($dir) = @_;
    opendir(J, $dir) or print "# error : couldn't parse the jobs directory \`$dir': $!\n", return 0;
    my @files = grep { /^[^.].+\.pl$/ } readdir(J);
    close(J);
    foreach(@files) {
	load_file($dir.'/'.$_);
    }
}

my $basedir = $0;
if($0 =~ /\//) { # with at least one path
    $basedir =~ s!/[^/]+$!!;
} else { # cwd
    $basedir = '.';
}
$basedir .= '/..';

my $conf = $ENV{HOME}.'/.lycanobot/config.xml';
if(defined($ARGV[0])) {
    if(-e $ARGV[0]) { # Seems good
	$conf = $ARGV[0];
    } else {
	die "Usage : $0 [lycanobot config file]\n"
    }
}

# Temporary disable printing lycanobot's stuff
open(my $oldout, ">&STDOUT")   or die "Can't dup STDOUT: $!";
open(STDOUT, '>', '/dev/null') or die "Can't redirect STDOUT: $!";

# Load config
our %files = ( 'basedir' => $basedir );
use constant DEFAULT_LANG => 'en';
include($basedir."/timer.pl"); # Needed by config.pl
include($basedir."/config.pl"); # Config file handling functions
load_lyca_config_file($conf) or die;

# Load the basics
include($basedir.'/send.pl'); # Needed by basics.pl
include($basedir.'/basics.pl');
load_game_basics();

# Load styles list
include($basedir."/games.pl");
load_games_config_file($ENV{'HOME'}.'/.lycanobot/games.xml') or die;

# Load the jobs list
include($basedir.'/speech.pl'); # Needed by jobs.pl
include($basedir.'/commands.pl'); # Needed by jobs.pl
include($basedir.'/jobs.pl');
load_jobs($basedir.'/jobs');

# Build the phases names
my @phs;
foreach(keys(%phases)) {
    if(defined($messages{'phases'}{$_}{'name'})) {
	push(@phs, charset_conv($messages{'phases'}{$_}{'name'}));
    } else {
	push(@phs, $_);
    }
}

# Build the jobs list
my @job;
foreach(keys(%special_jobs)) {
    push(@job, charset_conv($messages{'jobs_name'}{$_}));
}

# Build the services list
my @srv = keys(%{ $CFG{'hacks'}{'service'} });

# Build the styles list
my @sty = keys(%{ $games{'jobs'} });

# Build the syntax hash
my %cmd_syn =
(
 'help'       => '_cmd',
 'settimeout' => '_phs',
 'setcards'   =>
 { 'add' => '_job', 'del' => '_job', 'style' => '_sty', 'nostyle' => undef },
 'showstyle'  => '_sty',
 'tutorial'   => { 'on' => undef, 'off' => undef },
 'vote'       => '_ply',
 'talkserv'   => '_srv',
 'hlme'       => { map { $_ => undef } ( 'forever', 'quit', 'game', 'never' ) }
);
 
foreach(keys(%cmdlist)) {
    $cmd_syn{$_} = undef unless(exists($cmd_syn{$_}));
}

# Restore output
close(STDOUT);
open(STDOUT, ">&", $oldout) or die "Can't dup \$oldout: $!";

# Now print this out in a perl syntax
print gen_header();
print 'my $phs; my $job; my $srv; my $sty; my $cmd_syn;'."\n";
my $d = Data::Dumper->new([ \@phs, \@job, \@srv, \@sty, \%cmd_syn ]);
$d->Names(['phs', 'job', 'srv', 'sty', 'cmd_syn']);
$d->Indent(1);
print $d->Dump;

# And now the completion function
print '
foreach(keys(%$cmd_syn)) {
    $cmd_syn->{$cmd_prefix.$_} = delete $cmd_syn->{$_};
}

sub lyca_completion {
    my ($complist, $window, $word, $linestart, $want_space) = @_;
    
    my $dst = $window->get_active_name();
    my $deep = 0;
    my @words;
    my $do_it = grep { $_ eq $dst } @allowed_dst;
    $word = undef unless(length($word));

    unless($do_it) {
	foreach(@allowed_dst) {
	    if($linestart =~ /^\/(msg|query)( -\w+)* \Q$_\E */i) {
                $linestart =~ s/^\/(msg|query)( -\w+)* \Q$_\E *//i;
                $do_it = 1;
	        last;
            }
	}
    }

    return unless($do_it);

    if($linestart eq "") {
        return unless($word =~ /^$cmd_prefix/);
    } else {
        return unless($linestart =~ /^$cmd_prefix/); 
	@words = split(/ +/, $linestart);
    }

    push(@words, $word);
    parse_token($complist, $cmd_syn, @words);
}

sub parse_token {
    my ($complist, $syn, @words) = @_;
    my $token = shift(@words);

    if(@words) {
	if(ref($syn) eq "HASH" && exists($syn->{$token})) {
	    parse_token($complist, $syn->{$token}, @words);
	}
	return;
    }
    
    if(ref(\$syn) eq "SCALAR" && $syn =~ /^_/) {
	if($syn eq "_sty") {
	    push(@$complist, grep {
                 !defined($token) || $_ =~ /^\Q$token/i } @$sty);
	} elsif($syn eq "_phs") {
            push(@$complist, sort {
		   $a =~ /^\Q$token/i ? -1 : $b =~ /^\Q$token/i ? 1 : 0
		 } grep {
		     !defined($token) || $_ =~  /\Q$token/i
                 } @$phs);

	} elsif($syn eq "_job") {
            push(@$complist, sort {
		   $a =~ /^\Q$token/i ? -1 : $b =~ /^\Q$token/i ? 1 : 0
		 } grep {
                   !defined($token) || $_ =~  /\Q$token/i
		 } @$job);
	} elsif($syn eq "_srv") {
	    push(@$complist, grep {
		 !defined($token) || $_ =~ /^\Q$token/i } @$srv);
	} elsif($syn eq "_cmd") {
	    push(@$complist, grep {
                 !defined($token) || $_ =~ /^\Q$token/i }
		 sort map { s/\Q$cmd_prefix//; $_ } keys(%$cmd_syn));
	}
	return;
    }

    return unless(ref($syn) eq "HASH");

    # last word, may be incomplete
    if(exists($syn->{$token})) {
	return unless(defined($syn->{$token})); # End of $syn
        parse_token($complist, $syn->{$token}, @words);
        @$complist = map { $token." ".$_} @$complist;
        return;

    } else {
        my $add_pre = 0;
	foreach my $comp (sort keys(%$syn)) {
            if ($comp eq $token) {
		parse_token($complist, $syn->{$comp});
		@$complist = map { $token." ".$_} @$complist;
		return;
	    } elsif ($comp =~ /^\Q$token/i) {
	        push(@$complist, $comp);
            }
        }
    }
}

Irssi::signal_add_last "complete word" => \&lyca_completion;

my $last_char;
my $last_tab_line;
Irssi::signal_add_last "gui key pressed" => sub {
    my ($key) = @_;
    my $win = Irssi::active_win();
    my $inputline = Irssi::parse_special("\$L");

    if(chr($key) eq "\t" && defined($last_char) && $last_char eq $key
       && defined($last_tab_line) && $inputline eq $last_tab_line) {
        # get current inputline
        return unless ($inputline =~ /[^ ] $/);

        # get last bit from the inputline
        my @words = split(/ /, $inputline);
        my $word = pop(@words);
        my $linestart = join(" ", @words);
 
        my @complist;
        lyca_completion(\@complist, $win, $word, $linestart, 1);
        if(@complist > 1) {
            my ($prefix) = split(/ /, $complist[0]);
            unless(grep { !/^\Q$prefix\E / } @complist) {
                @complist = map { s/^\Q$prefix\E //; $_ } @complist;
            }
         $win->print(join(", ", @complist))
        }
    }
    $last_char = $key;
    $last_tab_line = $inputline;
}
';
