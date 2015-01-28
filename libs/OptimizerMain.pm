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
    
    my $pid = fork;
    
    if (!defined $pid) {
        die "cannot fork: $!";
    } elsif ($pid == 0) {
        # child does this
        close STDOUT;
        close STDERR;
        open STDERR, ">&=1";

        my $id = $self->session->id();
        my $appdir = $ENV{OPENSHIFT_REPO_DIR};
        
        my $tmpdir = $ENV{OPENSHIFT_TMP_DIR};
        my $pidloc = "$tmpdir" . "$id";
        make_path("$pidloc");
        my $pidfile = File::Pid->new({
            file => "$pidloc/running.pid"
        });
        $pidfile -> write;
        die "Didn't wait.";
        sleep 60;
        open OUTPUT, ">$tmpdir/results.txt";
        print OUTPUT localtime;
        close OUTPUT;
        $pidfile -> remove or warn "Couldn't unlink PID file\n";
        
        my $cmd = "$appdir" . '/wait-test.pl';
        exec "$cmd", "$id" or die "can't do exec: $!";
    } else {
        # parent does this
        return $self->redirect("/optimize-start.pl?rm=optimizer_status");
    }

}

sub optimizer_status : Runmode {
    my $self = shift;

    # Get ready to access PID file
    my $id = $self->session->id();
    my $tmpdir = $ENV{OPENSHIFT_TMP_DIR};
    my $datadir = $ENV{OPENSHIFT_DATA_DIR};
    my $appdir = $ENV{OPENSHIFT_REPO_DIR};
    my $pidloc = "$tmpdir" . "$id";
    
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

    open OUTPUT, ">$datadir/results.txt";
    print OUTPUT "Printed by redirect.";
    print OUTPUT localtime;
    close OUTPUT;


    my $template = $self->load_tmpl($appdir . '/optimizer-results.html');
    $template->param(
                TITLE  => "Optimizer Status",
                STILL_RUNNING  => $still_running,
                RESULT_FILE => "$datadir" . "results.txt"
            );
    return $template->output;
}

1;
