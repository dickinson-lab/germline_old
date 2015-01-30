#!/usr/bin/perl

use strict;
use warnings;

use HTML::Template;

my $datadir = $ENV{OPENSHIFT_DATA_DIR};
my $tmpdir = $datadir . 'tmp/';
open OUTPUT, ">", $tmpdir . 'results.txt';
print OUTPUT "Hello World!\n";
print OUTPUT localtime, "\n";
close OUTPUT;

my $appdir = $ENV{OPENSHIFT_REPO_DIR};
my $template = HTML::Template->new( filename => $appdir . '/optimizer-results.html' );
$template->param(
            TITLE  => "tmp Test",
            RESULT_FILE => $tmpdir . 'results.txt'
        );

print "Content-Type: text/html\n\n";
print "<p1>Temp location is $tmpdir\n";
print "App location is $appdir\n";
open TXTFILE, "<", $tmpdir . 'results.txt' or die "Can't find file";
while (my $a = <TEXTFILE>) {
    print "$a\n";
}
print "<p1>", $template->output;

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