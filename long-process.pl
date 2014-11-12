use strict;
use CGI::Session;

my $session = shift;
my $cache = CGI::Session->load ($session);

$cache->param('status', "configuring ..."); # no data yet

my $end = time () + 20;
my $count = 0;

while (time () < $end) {
    $cache->param ('status', "Count: $count\n");
    $cache->flush ();
    ++$count;
    sleep (1);
}

$cache->param ('status', "Completed");
$cache->flush ();
exit 0; # all done
