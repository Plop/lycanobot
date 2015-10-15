# actions.pl
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


use strict;
use warnings;
################################
# actions managing

our (%messages, %phs);

# This hash describes some typical actions that appears in game.
# Each action is a key of this hash, that contains subs reference to some
# things to do. It can have pre, post and replace hooks. Each of these keys may
# be a simple sub, or an array of subs, which will be executed sequentially.
# The replace hook actually replaces the action call (key 'sub') unless it
# returns undef, which means its call was useless.
#
# These actions are called with:
# do_action($action_tame, $target, @extra_args); # Call the action and its hooks
#
# Any @extra_args are given to all the subs that are in %actions.
#
our %actions = ( # Filled by basics.pl
# 'action_name' => {
#    'sub' => \&do_my_dear_action,
#    'hooks' => {
#        'before'  => \&do_that,                # A simple sub
#        'replace' => \&try_to_do_this,         # Replaces unless undef returned
#        'after'   => [ \&do_this, \&and_this ] # Sequential call of all subs
#    }
# }
);

# This hash says who can do what action, when and how.
# It's intended to be dynamically filled and modified whithin each game.
#
# Any action in the %actions hash above may have its auth settings here.
# It works a bit like iptables: each action has:
# - A policy, either 'accept' or 'deny'. It defines the default beheaviour when
#   none of the 'deny' or 'accept' blocks matches. It defaults to 'accept'.
#
# - Some other keys, each defining a rule. Theses keys points to a hash with 
#   some contextual informations. The rule matches if these infos matches the
#   action context call. If the policy is 'accept', a matching rule makes the
#   action to be denied, and if the policy is 'deny', it makes it accepted.
#
#   Note, what we call the "action args" are the do_action() args minus the
#   action name (first do_action() arg). It's the @a[1..-1] of do_action(@a).
#
#   The context consists of one or more of the following informations:
#   the current phase name, the (at least firsts) action args,
#   or a dedicated subroutine (called on the fly) that must return 1 to match.
#
# - An optional 'failsub' key may be also supplied along with a deny rule or
#   policy. If the policy or the rule denied the action, the pointing coderef
#   is executed with the action args.
#
our %actions_auth = (
#    'action_name' => {
#       'policy' => 'accept',
#       'my_evil_rule' => {
#           'phase'  => 'phase_name',   # \   One or more of these keys may be
#           'args' => [ 'foo', 'bar' ], #  `- present, but all of them must
#           'map_args' => \&my_map,     #  /  match to deny the action.
#           'sub'  => \&auth_test_sub,  # /   
#           'failsub' => sub { print "It's evil: he can't do that now !\n" }
#       },
#       'another_rule' => { ... }
#    },
#    'another_action' => {
#       'policy' => 'deny',
#       'some_rule' => { ... } # makes the action accepted if it matches
#       'failsub' => \&do_policy_stuff
#    }
);

# Adds an authentication rule and prints it.
# Arg 1: action name
# Arg 2: rule name
# Arg 3: rule hashref definition
sub add_action_auth_rule {
    my ($action, $name, $rule) = @_;

    if(exists($actions_auth{$action}{$name})) {
	print "# error : rule \`$name' of action \`$action' already exists\n";
	return;
    }
    unless(ref($rule) eq 'HASH') {
	print "# error : rule \`$name' of action \`$action' is not a hashref\n";
	return;
    }

    $actions_auth{$action}{$name} = $rule;
    print "-> Added rule $name to action $action, matching on"
	.(exists($$rule{'phase'}) ? " phase" : "")
	.(exists($$rule{'args'}) ? " args" : "")
	.(exists($$rule{'sub'}) ? " sub-call" : "")."\n";
}

# Sets the policy of an action.
# Arg 1: action name
# Arg 2: policy (either 'accept' or 'deny')
# Arg 3 (optionnal, only if arg 2 is 'deny'): the failsub 
sub set_action_auth_policy {
    my ($action, $pol, $failsub) = @_;

    unless(exists($actions_auth{$action})) {
	print "# error : can't set the policy of action \`$action' : this action not exists\n";
	return;
    }
    if($pol eq 'accept') {
	$actions_auth{$action}{'policy'} = $pol;
    } elsif($pol eq 'deny') {
	$actions_auth{$action}{'policy'} = $pol;
	if(defined($failsub)) {
	    $actions_auth{$action}{'failsub'} = $failsub;
	}
    }
}

# Tests if an action is allowed, using the %action_auth authentication infos.
# Returns 0 if an action is deny, 1 if allowed or there are no authentication
# informations about the given action.
# Args are what you would give to do_action().
sub auth_action {
    my ($act, @args) = @_;
    my $policy = 'accept';
    my $matches;
    my $p = 1;
    my $params;

    return 1 unless(exists($actions_auth{$act}));

    if(exists($actions_auth{$act}{'policy'})) {
	$policy = $actions_auth{$act}{'policy'};
    }

    $p = ($policy eq 'accept');

    foreach my $rule (keys(%{ $actions_auth{$act} })) {
	next if($rule eq 'policy');
	$matches = 1;

	if($matches && exists($actions_auth{$act}{$rule}{'phase'})) {
	    $matches &= ($actions_auth{$act}{$rule}{'phase'} eq $phs{'current'});
	}
	if($matches && exists($actions_auth{$act}{$rule}{'args'})) {
	    $params = $actions_auth{$act}{$rule}{'args'};
	    if(ref($actions_auth{$act}{$rule}{'map_args'}) eq 'CODE') {
		@$params = map {
		    $actions_auth{$act}{$rule}{'map_args'}->($_) } @$params;
	    }
	    foreach (0 .. $#$params) {
		$matches &= ($$params[$_] eq $args[$_]) if(exists($args[$_]));
	    }
	}
	if($matches && ref($actions_auth{$act}{$rule}{'sub'}) eq 'CODE') {
	    $matches &= $actions_auth{$act}{$rule}{'sub'}->();
	}

	if($matches) { # Rule $rule matched
	    print "-> Action $act(".join(", ",@args).") denied by rule $rule\n";
	    if($p && exists($actions_auth{$act}{$rule}{'failsub'})
		&& ref($actions_auth{$act}{$rule}{'failsub'}) eq 'CODE') {
		# $rule denied the action
		$actions_auth{$act}{$rule}{'failsub'}->(@args);
	    }
	    return !$p;
	}
    }

    if(!$p) {
	# policy denied the action
	print "-> Action $act denied by the policy\n";
	if(exists($actions_auth{$act}{'failsub'})
	   && ref($actions_auth{$act}{'failsub'}) eq 'CODE') {
	    $actions_auth{$act}{'failsub'}->(@args);
	}
    }

    return $p; # None of the rules matched, adopt policy
}

# Do an action if we are allowed to.
# Returns auth_action()'s result
sub do_action_if_auth {
    my @action_args = @_;
    my $auth = auth_action(@action_args);
    
    do_action(@action_args) if($auth);
    return $auth;
}

# Adds an action to the %actions hash, optionnaly with some hooks
# Arg 1: action name
# Arg 2: action sub
# Arg 3 (optionnal): a hash of the hooks
sub add_action {
    my ($act, $sub, $hooks) = @_;

    if(exists($actions{$act})) {
	print "# warning : attempting to add an already existing action: $act\n";
	return;
    }
    unless(ref($sub) eq 'CODE') {
	print "# error : for action $act, sub is not a coderef, $act ignored\n";
	return;
    }

    $actions{$act}{'sub'} = $sub;
    $actions{$act}{'hooks'} = undef;
    while(my ($type, $subs) = each(%$hooks)) {
	add_action_hook($act, $type, $subs);
    }
}

# Adds a hook to an action, with one or more attached subs.
# Arg 1: action name
# Arg 2: hook type (before, replace or after)
# Arg 3: a sub or an array of subs
sub add_action_hook {
    my ($act, $type, $subs) = @_;
    unless($type eq 'before' || $type eq 'replace' || $type eq 'after') {
	print "# error : action $act hook can be either before, replace or "
	    ."after, but not \`$type'; hook ignored\n";
	return;
    }

    if(ref($subs) eq 'ARRAY') { # An array of subs was given
	add_action_hook($act, $type, $_) foreach(@$subs);
    } else { # Only a single sub given
	unless(ref($subs) eq 'CODE') {
	    print "# error : for action $act, hook type $type, sub is not a coderef, hook ignored\n";
	    return;
	}

	if(exists($actions{$act}{'hooks'}{$type})
	   && ref($actions{$act}{'hooks'}{$type}) eq 'ARRAY') { # Just push()
	    push(@{ $actions{$act}{'hooks'}{$type} }, $subs);
	} else { # First one, create the array
	    $actions{$act}{'hooks'}{$type} = [ $subs ];
	}
    }
}

# This sub is called at each game end and at lycanobot's startup.
# It contains the actions names that have their results kept here.
our %last_actions;

# Prints a line indented with as many spaces as @{ $phs{'hooks'}{'stack'} }
sub hprint {
    print '  'x@{$phs{'hooks'}{'stack'}};
    print @_;
}

# Returns a default hash for $phs{'hooks'}. May take the stack as first arg.
sub phs_hooks_init {
    return { 'pos' => 'after',     'sub' => 0,
	     'action_args' => [ ], 'stack' => $_[0] || [ ] };
}

# Do action can be called in 2 way:
# - The normal way, with its args, and it executes the given action.
# - The stack-call-simulation way, without args. It reads its args in
#   $phs{'hooks'}{'action_args'} and to not push anything on the hooks stack.
#   Used to come back from a cut phase, by execute_next_hooks().
sub do_action {
    my ($action, @extra_args) = @_;
    my ($result, $cut);
    my $phooks = \$phs{'hooks'};
    my @cut_flag = (1, 1);

    unless(@_) {
	($action, @extra_args) = @{ $$$phooks{'action_args'} };
    }

    # If we are already in some hook (that is, a hook called another one),
    # keep the current informations on the hook stack, we'll get them later.
    elsif(@{ $$$phooks{'action_args'} }) {
	push(@{ $$$phooks{'stack'} },
	     { 'pos'         => $$$phooks{'pos'},
	       'sub'         => $$$phooks{'sub'},
	       'action_args' => $$$phooks{'action_args'} });
	$$phooks = phs_hooks_init($$$phooks{'stack'});
    }

    # Pre-event hooks
    if($$$phooks{'pos'} eq 'after') {
	# This does $$$phooks{'pos'} = 'after'
	$$phooks = phs_hooks_init($$$phooks{'stack'});

	# We entered do_action(), so we set the do_action_args %phs key
	$$$phooks{'action_args'} = [ @_ ];

	hprint "-> Action $action";
	print "(@extra_args)" if(@extra_args);
	print "\n";

	($result, $cut) = do_hooks($action, 'before', @extra_args);
	return @cut_flag if($cut);
	$$$phooks{'pos'} = 'before';
    }

    if($$$phooks{'pos'} eq 'before') {
	# See if we have a replacement for this event
	($result, $cut) = do_hooks($action, 'replace', @extra_args);
	return @cut_flag if($cut);

	unless(defined($result)) {
	    $$$phooks{'pos'} = 'sub';
	    # No, so execute it !
	    if(ref($actions{$action}{'sub'}) eq 'CODE') {
		($result, $cut) = $actions{$action}{'sub'}->(@extra_args);
		return @cut_flag if($cut);
	    }
	} else {
	    $$$phooks{'pos'} = 'sub';
	}
    }

    # Post-event hooks
    if($$$phooks{'pos'} eq 'sub') {
	($result, $cut) = do_hooks($action, 'after', @extra_args);
	return @cut_flag if($cut);
	$$$phooks{'pos'} = 'after';
	$$$phooks{'action_args'} = [ ]; # We finished do_action()

	# Retrive any pushed hook
	if(@{ $$$phooks{'stack'} }) {
	    my $kept = pop(@{$$$phooks{'stack'}});
	    $$$phooks{'action_args'} = $$kept{'action_args'};
	    $$$phooks{'sub'}         = $$kept{'sub'};
	    $$$phooks{'pos'}         = $$kept{'pos'};
	}
    }
}

sub do_hooks {
    my ($action, $when, @args) = @_;
    my ($result, $hook, $cut);
    my $subs = $actions{$action}{'hooks'}{$when};
    my $phooks = \$phs{'hooks'};

    if(ref($subs) eq 'CODE') {
	$subs = [ $subs ];
    }

    if(ref($subs) eq 'ARRAY') {
	foreach ($$$phooks{'sub'} .. $#$subs) {
	    $hook = $$subs[$_];
	    if(ref($hook) eq 'CODE') {
		$$$phooks{'sub'} = $_+1;
		hprint "-> Execing $when-hook number $_ of $action ("
		    .join(',',@args).")\n";
		($result, $cut) = $hook->(@args);
		return ($result, $cut) if($cut);
		# The first successfull replace hook overstep the others
		last if($when eq 'replace' && defined($result));
	    }
	}
    }
    $$$phooks{'sub'} = 0;
    return $result;
}

# Writes an action result in %last_actions, performing some sanity checks :
# prints a warning if it overwrites a hash with a non-hash,
# or a non-hash with a hash.
# Arg 1: action result
# Arg 2: action name
# Other args(optionnal): subkeys if you wanna store several results for 1 action
#
# Examples:
#  write_last_action_result('done', 'myaction');
#  does $last_actions{'myaction'} = 'done';
#
#  write_last_action_result('foo', 'stuff', 'out');
#  does $last_actions{'stuff'}{'out'} = 'foo';
#  write_last_action_result('bar', 'stuff', 'out', 'blah');
#  does $last_actions{'stuff'}{'out'}{'blah'} = 'bar' and prints a warning
sub write_last_action_result {
    our %last_actions;
    my ($res, $act, @subkeys) = @_;
    my ($hash, $key);

    unless(defined($res)) {
	print "# warning : missing action result in write_last_action_result()\n";
	return;
    }
    unless(defined($act)) {
	print "# warning : missing action name in write_last_action_result()\n";
	return;
    }

    $hash = \%last_actions;
    $key = $act;
    while(@subkeys) {
	if(exists($$hash{$key})) {
	    if(ref($$hash{$key}) ne 'HASH') {
		print "# warning: in write_last_action_result():\n";
		print "#          for action \`$act'";
		print ", key \`$key'" if($key ne $act);
		print ":\n#          overwriting existing result \`".$$hash{$key}."' with key \`".$subkeys[0]."'\n";
		$$hash{$key} = {};
	    }
	} else {
	    $$hash{$key} = {};
	}
	$hash = $$hash{$key};
	$key = shift(@subkeys);
    }
    if(ref($$hash{$key}) eq 'HASH' && keys(%{ $$hash{$key} })) {
	print "# warning: in write_last_action_result():\n";
	print "#          for action \`$act':\n";
	print "#          overwriting existing key(s) "
	    .join(",", map {"\`$_\'"} keys(%{ $$hash{$key} }))
	    ." using result \`$res'\n";
    }

    $$hash{$key} = $res;
}

# The conterpart of write_last_action_result(). Reads through %last_actions.
# Prints a warning if the result couldn't be read beacause the hashtree do not
# match the args.
#
# Arg 1: action name
# Other args(optionnal): subkeys
# Returns the stored result if found, or undef instead.
sub read_last_action_result {
    our %last_actions;
    my ($act, @subkeys) = @_;
    my ($hash, $key);

    unless(defined($act)) {
	print "# warning : missing action name in read_last_action_result()\n";
	return undef;
    }

    $hash = \%last_actions;
    $key = $act;
    while(@subkeys) {
	if(exists($$hash{$key})) {
	    if(ref($$hash{$key}) ne 'HASH') {
		print "# warning: in read_last_action_result('".join("', '",@_)."'):\n";
		print "#          couldn't read result through key \`".$subkeys[0]."': existing result \`".$$hash{$key}."' instead.\n";
		return undef;
	    }
	}
	$hash = $$hash{$key};
	$key = shift(@subkeys);
    }
    if(ref($$hash{$key}) eq 'HASH' && keys(%{ $$hash{$key} })) {
	print "# warning: in read_last_action_result('".join("', '",@_)."'):\n";
	print "#          no result found: existing key(s) "
	    .join(",", map {"\`$_\'"} keys(%{ $$hash{$key} }))
	    ." instead.\n";
	return undef;
    }

    return $$hash{$key};
}

# Acts like read_last_action_result() but also deleting the result.
# Prints a warning if the result couldn't be read beacause the hashtree do not
# match the args.
#
# Arg 1: action name
# Other args(optionnal): subkeys
# Returns the deleted result if found, or undef instead.
sub delete_last_action_result {
    our %last_actions;
    my ($act, @subkeys) = @_;
    my ($hash, $key);

    unless(defined($act)) {
	print "# warning : missing action name in delete_last_action_result()\n";
	return undef;
    }

    $hash = \%last_actions;
    $key = $act;
    while(@subkeys) {
	if(exists($$hash{$key})) {
	    if(ref($$hash{$key}) ne 'HASH') {
		print "# warning: in delete_last_action_result('".join("', '",@_)."'):\n";
		print "#          couldn't read through key \`".$subkeys[0]."': existing result \`".$$hash{$key}."' instead.\n";
		return undef;
	    }
	}
	$hash = $$hash{$key};
	$key = shift(@subkeys);
    }
    return delete $$hash{$key};
}

# The final "1"
# Don't delete it, otherwise including this file will result as an error
1
