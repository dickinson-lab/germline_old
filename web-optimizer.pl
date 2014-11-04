#!/usr/bin/perl
use strict;
use warnings;

use 5.010;
use CGI;
use BerkeleyDB;
use Math::Random;
use lib '/libs/Seqscore.pm';

my $datadir = $ENV{OPENSHIFT_DATA_DIR};

my $sequence_lib = new BerkeleyDB::Btree
    -Filename => join('',$datadir,'sequence_lib_scores.db');

# Set up output page
my $q = CGI->new();
say $q->header(), $q->start_html();

# Process and display sequence name
my $in_name = $q->param('name');
my $safename = $q->escapeHTML($in_name);
if ( $safename ) {
    say "<h2>Results for sequence $safename</h2>";
} else {
    say "<h2>Results</h2>";
}


print "<p>Processing Input...</p>";

my $inseq = $q->param('sequence');
my $safeseq = $q->escapeHTML($inseq);

say "<p> Input: $safeseq";
$sequence_lib -> db_get($safeseq, my $score);
say "Score: $score </p>";

say $q->end_html();
