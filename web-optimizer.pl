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
my $seqtype = $q->param('seq_type');

# Check sequence for invalid characters
my $bio_seq = Bio::Seq->new();

if ( ! $bio_seq->validate_seq($safeseq) ) {
    error("You entered an invalid sequence");
}

# If sequence is ok, make a Bio::Seq object out of it
my $seqobj = Bio::Seq->new( -sequence => $safeseq );

# Check sequence for correct type, generate amino acid sequence
my $AAseq;
if ($seqtype eq 'AA') {
    if ( $seqobj->alphabet ne 'protein' ) {
        error("You selected \"Amino Acid,\" but your input doesn't appear to be an amino acid sequence. Please check the sequence and try again");
    }
    $AAseq = $seqobj->seq();
} elsif ($seqtype eq 'DNA') {
    if ( $seqobj->alphaet ne 'dna') {
        error("You selected \"DNA,\" but your input doesn't appear to be a nucleotide sequence. Please check the sequence and try again");
    }
    $AAseq = $seqobj->translate();
} else {
    error("Program error :-\("); #You'd only get this if the HTML form returned the wrong value.
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