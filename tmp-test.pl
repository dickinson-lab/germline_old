#!/usr/bin/perl

use strict;
use warnings;

use HTML::Template;

my $tmpdir = $ENV{OPENSHIFT_TMP_DIR};
open OUTPUT, ">", $tmpdir . 'results.txt';
print OUTPUT "Hello World!";
print OUTPUT localtime;
close OUTPUT;

my $appdir = $ENV{OPENSHIFT_REPO_DIR};
my $template = HTML::Template->new( filename => $appdir . '/tmp-test-tmpl.html' );
$template->param(
            TITLE  => "tmp Test",
            RESULT_FILE => $tmpdir . 'results.txt'
        );

say "Temp location is $tmpdir";
say "App location is $appdir";
open TXTFILE, "<", $tmpdir . 'results.txt';
while (my $a = <TEXTFILE>) {
    say "$a";
}
print "Content-Type: text/html\n\n", $template->output;

 #Contents of tmp-test-tmpl.html:
 #
 #   <head>
 #       <title> <TMPL_VAR NAME=TITLE> </title>
 #   </head>
 #   
 #   <body>
 #       <h3> Job Complete! </h3>
 #       <iframe src=<TMPL_VAR NAME=RESULT_FILE> >
 #       </iframe>
 #   </body>