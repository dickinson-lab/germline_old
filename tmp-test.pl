#!/usr/bin/perl

use strict;
use warnings;

use HTML::Template;
use CGI::Carp qw(fatalsToBrowser);

my $datadir = $ENV{OPENSHIFT_DATA_DIR};
my $tmpdir = $datadir . 'tmp/';
open OUTPUT, ">", $datadir . 'results.txt' or die "Can't create tmp file";
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
print "<p1>Temp location is $tmpdir</p1>";
print "<p1>App location is $appdir</p1>";
print "<p1>Looking for file at " . $datadir . 'results.txt' . "</p1>";
open TXTFILE, "<", $tmpdir . 'results.txt' or die "Can't find tmp file";
while (my $a = <TEXTFILE>) {
    print "<p1>$a</p1>";
}
print $template->output;

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