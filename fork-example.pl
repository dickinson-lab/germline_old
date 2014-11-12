#!Perl -w
use strict;
use CGI::Pretty qw(:standard :cgi-lib);
use CGI::Carp qw(fatalsToBrowser); # Remove for production code
use CGI::Session;
use CGI qw(:all delete_all escapeHTML);

$CGI::DISABLE_UPLOADS = 1;         # Disable uploads
$CGI::POST_MAX        = 10240; # Maximum number of bytes per post

$| = 1; # Unbuffered output

if (param('Spawn')) {
    # setup monitoring page then spawn the monitored process
    my $cache = CGI::Session->new ();
    my $session = $cache->id();
   
    $cache->param ('status', "wait ..."); # no data yet
    #Delete_all();
   
    #FORK
    defined (my $kid = fork) or die "Cannot fork: $!\n";
    if ($kid) {
        delete_all();
        param('session', $session);
        print redirect (self_url());
    } else {
        close STDOUT;
        unless (open F, "-|") {
            open STDERR, ">&=1";
            exec "/long-process.pl", $session;
            die "Cannot execute program";
        }

        exit 0; # all done
    }
    
} elsif (my $session = param('session')) {
    # display monitored data
    my $cache = CGI::Session->new ($session);
    my $data = $cache->param ('status');
   
    if (! $data) { # something is wrong
        showError ("Cache data not available");
        exit 0;
    }
   
    my $headStr = $data eq 'Completed' ? '' : "<meta http-equiv=refresh content=5>";
    print header();
    print start_html (-title => "Spawn Results", -head => [$headStr]);
    print h1("Spawn Results");
    print pre(escapeHTML($data));
    print end_html;
 
} else {
    # display spawn form
    print header(), start_html("Spawn"), h1("Spawn");
    print start_form();
    print submit('Spawn', 'spawn');
   
    my %params = Vars ();
    for my $param (keys %params) {
        print br ("$param -> $params{$param}");
    }
   
    print end_form(), end_html();
}

exit 0;


sub showError {
    print header(), start_html("SpawnError"), h1("Spawn Error");
    print p (shift);
   
    my %params = Vars ();
    for my $param (keys %params) {
        print br ("$param -> $params{$param}");
    }
   
    print end_html();
}