#!/usr/bin/perl
use strict;
use warnings;

use 5.010;
use CGI;
use BerkeleyDB;
use Bio::Seq;
use Math::Random;
use lib '/libs/Seqscore.pm';
use lib '/libs/OptimizerTools.pm';

my $datadir = $ENV{OPENSHIFT_DATA_DIR};

my $sequence_lib = new BerkeleyDB::Btree
    -Filename => join('',$datadir,'sequence_lib_scores.db');

### SET UP ###

# Set up output page
my $q = CGI->new();
say $q->header(), $q->start_html();

# Get input
my $inseq = $q->param('sequence');
my $safeseq = $q->escapeHTML($inseq);
$safeseq =~ s/\s+//g; #Remove whitespace
my $seqtype = $q->param('seq_type');
my $add_introns = $q->param('introns');

# Check sequence for invalid characters
my $bio_seq = Bio::Seq->new();

if ( ! $bio_seq->validate_seq($safeseq) ) {
    error("You entered an invalid sequence");
}

# If sequence is ok, make a Bio::Seq object out of it
my $seqobj = Bio::Seq->new( -seq => $safeseq );

# Check sequence for correct type, generate amino acid sequence
my $AAseq;
if ($seqtype eq 'AA') {
    if ( $seqobj->alphabet ne 'protein' ) {
        error("You selected \"Amino Acid,\" but your input doesn't appear to be an amino acid sequence. Please check the sequence and try again.");
    }
    $AAseq = $seqobj->seq();
} elsif ($seqtype eq 'DNA') {
    
    if ( $seqobj->alphabet ne 'dna') {
        error("You selected \"DNA,\" but your input doesn't appear to be a nucleotide sequence. Please check the sequence and try again.");
    }
    my $trans = $seqobj->translate();
    $AAseq = $trans->seq();
} else {
    error("Program error :-\("); #You'd only get this if the HTML form returned the wrong value.
}


### IF A NUCLEOTIDE SEQUENCE WAS ENTERED, CALCULATE ITS SCORE ###

if ($seqtype eq 'DNA') {
    my @input_coding_sequence = unpack("(A3)*", $seqobj->seq());
    my ( $input_sequence_score, $input_lowest_score, $input_n_w_lowest_score ) = Seqscore::score_sequence( \@input_coding_sequence, $sequence_lib );
}


### OPTIMIZE THE SEQUENCE ###

my $optimization_results = OptimizerTools::optimize($sequence_lib, $AAseq);


### DISPLAY RESULTS ###

# Process and display sequence name
my $in_name = $q->param('name');
my $safename = $q->escapeHTML($in_name);
if ( $safename ) {
    say "<h2>Results for sequence \"$safename\"</h2>";
} else {
    say "<h2>Results</h2>";
}

# If input was a nucleotide sequence, display score
if ($seqtype eq 'DNA') {
    say "<p>Input Sequence Score: $input_sequence_score";
    say "Lowest Word Score: $input_lowest_score \($input_n_w_lowest_score words\)";
    say "</p><br><br>";
}

# Display optimized sequence and score
say "<p>Opmized Sequence Score: $optimization_results->{'Sequence_score'}";
say "Lowest Word Score: $optimization_results->{'Lowest_score'} \($optimization_results->{'Words_w_lowest_score'} words\)";
say "Sequence:";
say join( "\n", unpack( "(A60)*", $optimization_results->{'Sequence'}) );
say "</p>";

say $q->end_html();

sub error {
    my $errormsg = shift;
    say("<h2>Error</h2>");
    say("<p>$errormsg</p>");
    say $q->end_html();
    exit;
}

#say "<p>Well, I got this far</p>";

#say "<p> Input: $safeseq";
#$sequence_lib -> db_get($safeseq, my $score);
#say "Score: $score </p>";