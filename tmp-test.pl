#!/usr/bin/perl

use strict;
use warnings;

use HTML::Template;

my $tmpdir = $ENV{OPENSHIFT_TMP_DIR};
open OUTPUT, ">", $tmpdir . 'results.txt';
print OUTPUT "Hello World!";
print OUTPUT localtime;
close OUTPUT;


my $template = $self->load_tmpl($appdir . '/optimizer-results.html');
$template->param(
            TITLE  => "Optimizer Status",
            STILL_RUNNING  => $still_running,
            RESULT_FILE => $tmpdir . 'results.txt'
        );
return $template->output;