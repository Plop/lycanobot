our $conn;
add_action_hook('death_announce', 'after', \&on_deathannounce);

sub on_deathannounce {
my $dead = shift;
return if($players{$dead}{'alive'});
$dead =~ s/"/\\"/;
$conn->privmsg('#loups-garous-control-YAGALALIO','{"event":"death", "nick":"'.$dead.'"}');
}
