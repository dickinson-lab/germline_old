#!/usr/bin/perl

package OptimizerMain;

use strict;
use warnings;

use 5.010;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Redirect;
use HTML::Template;
use File::Pid;


sub start_optimization : StartRunmode {
    my $self = shift;
    
    if (my $pid = fork) {
        # parent does this
        return $self->redirect("/optimize-start.pl?rm=optimizer_status");
    } elsif (defined $pid) {
        # child does this
        close STDOUT;
        close STDERR;
        open STDERR, ">&=1";

        my $id = $self->session->id();
        my $cmd = '/wait_test.pl';
        exec "$cmd", "$id";
        die "can't do exec: $!";

    } else {
        die "cannot fork: $!";
    }

}

sub optimizer_status : Runmode {
    my $self = shift;

    # Get ready to access PID file
    my $id = $self->session->id();
    my $tmpdir = $ENV{OPENSHIFT_TMP_DIR};
    my $pidloc = "$tmpdir" . '/' . "$id";
    
    my $pidfile = File::Pid->new({
        file => "$pidloc/running.pid"
    });
    
    # Check if process is still running
    my $still_running = 0;
    if ( -e "$pidloc/running.pid" ) {
        if ( $pidfile -> running ) {
            $still_running = 1;
        } else {
            $still_running = 0;
        }
    }

    my $template = HTML::Template -> new( filename => 'optimizer-results.html');
    $template->param(
                TITLE  => "Optimizer Status",
                STILL_RUNNING  => $still_running
            );
    return $template->output;
}

1;
