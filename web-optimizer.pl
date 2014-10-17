#!/usr/bin/perl
use strict;
use warnings;

use 5.010;
use CGI;
use BerkeleyDB;
use Math::Random;
use lib '/libs/Seqscore.pm';

my $q = CGI->new();
say $q->header(), $q->start_html();

say "<h1>Results</h1>";

say "<p>Processing Input...</p>";

my $inseq = $q->param('sequence');
my $safeseq = $q->escapeHTML($inseq);

say "<p>$safeseq</p>";

say $q->end_html();
