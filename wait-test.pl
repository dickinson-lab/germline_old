#!/usr/bin/perl
use strict;
use warnings;

use 5.010;
use File::Pid;
use File::Path qw(make_path);

# Set location for PID file
my $id = shift;
my $tmpdir = $ENV{OPENSHIFT_TMP_DIR};
my $pidloc = "$tmpdir" . '/' . "$id";
make_path("$pidloc");

my $pidfile = File::Pid->new({
    file => "$pidloc/running.pid"
});

$pidfile -> write;

sleep 60;

$pidfile -> remove or warn "Couldn't unlink PID file\n";

