#!/usr/bin/perl
use strict;
use warnings;

use 5.010;
use CGI;
use BerkeleyDB;
use Math::Random;
use lib '/libs/Seqscore.pm';

my $datadir = $ENV{OPENSHIFT_DATA_DIR};

say "<p> Data Dir: $datadir </p>";

my $sequence_lib = new BerkeleyDB::Btree
    -Filename => '/libs/sequence_lib_scores.db';

my $q = CGI->new();
say $q->header(), $q->start_html();

say "<h1>Results</h1>";

print "<p>Processing Input...</p>";

my $inseq = $q->param('sequence');
my $safeseq = $q->escapeHTML($inseq);

say "<p> Input: $safeseq";
$sequence_lib -> db_get($safeseq, my $score);
say "Score: $score </p>";

say $q->end_html();
