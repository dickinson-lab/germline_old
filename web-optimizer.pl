#!/usr/bin/perl
use strict;
use warnings;

use 5.010;
use CGI;
use BerkeleyDB;
use Bio::Seq;
use Math::Random;
use lib '/libs/Seqscore.pm';

my $datadir = $ENV{OPENSHIFT_DATA_DIR};

my $sequence_lib = new BerkeleyDB::Btree
    -Filename => join('',$datadir,'sequence_lib_scores.db');

# Set up output page
my $q = CGI->new();
say $q->header(), $q->start_html();

# Get input sequence
my $inseq = $q->param('sequence');
my $safeseq = $q->escapeHTML($inseq);
$safeseq =~ s/\s+//g; #Remove whitespace

say "<p>$safeseq OK here</p>";
my $seqtype = $q->param('seq_type');

# Check sequence for invalid characters
if ( ! $seqobj->validate_seq($seqobj->seq()) ) {
    error("You entered an invalid sequence");
}

my $seqobj = Bio::Seq->new();

if ($seqtype eq 'AA') {
    if ( $seqobj->alphabet ne 'protein' ) {
        error("You selected \"Amino Acid\", but your input doesn't appear to be an amino acid sequence. Please check the sequence and try again");
    }
}


# Process and display sequence name
my $in_name = $q->param('name');
my $safename = $q->escapeHTML($in_name);
if ( $safename ) {
    say "<h2>Results for sequence \"$safename\"</h2>";
} else {
    say "<h2>Results</h2>";
}

say "<p> Input: $safeseq";
$sequence_lib -> db_get($safeseq, my $score);
say "Score: $score </p>";

say $q->end_html();

sub error {
    my $errormsg = shift;
    say("<h2>Error</h2>");
    say("<p>$errormsg</p>");
    say $q->end_html();
    exit;
}