add_command('restart', {
'descr' => 'Admin command restart.',
'subaddr' => \&cmd_restart,
'need_admin' => 1,
'game_cmd' => 0
});
sub cmd_restart {
our $conn;
    $conn->quit("Restarting...");
    $::irc->removeconn($conn);
    exec($0, @ARGV);
    return 1;
}
