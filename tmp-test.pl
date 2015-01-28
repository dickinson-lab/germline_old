#!/usr/bin/perl

use strict;
use warnings;

use HTML::Template;

my $tmpdir = $ENV{OPENSHIFT_TMP_DIR};
open OUTPUT, ">", $tmpdir . 'results.txt';
print OUTPUT "Hello World!";
print OUTPUT localtime;
close OUTPUT;

my $still_running = 1;

my $appdir = $ENV{OPENSHIFT_REPO_DIR};
my $template = HTML::Template->new($appdir . '/optimizer-results.html');
$template->param(
            TITLE  => "Optimizer Status",
            STILL_RUNNING  => $still_running,
            RESULT_FILE => $tmpdir . 'results.txt'
        );
return $template->output;