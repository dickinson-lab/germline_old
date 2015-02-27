#!/usr/bin/perl
use strict;
use warnings;

use 5.010;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use HTML::Template;
use JSON;
use BerkeleyDB;
use lib '/libs/';
use Seqscore;
use OptimizerTools;

#$| = 1;  # Disable buffering

my $datadir = $ENV{OPENSHIFT_DATA_DIR};

my $sequence_lib = new BerkeleyDB::Btree
    -Filename => join('',$datadir,'sequence_lib_scores.db');

### SET UP ###

# Get input
my $q = CGI->new();
print "Content-Type: text/html\n\n", $q->param('data');
exit;
my $userinput = decode_json($q->param('data'));
my $seqname = $userinput->{'name'};
my $dnaseq = $userinput->{'DNAseq'};
my $AAseq = $userinput->{'AAseq'};
my $seqtype = $userinput->{'seqtype'};
my $add_introns = $userinput->{'add_introns'};

### IF A NUCLEOTIDE SEQUENCE WAS ENTERED, CALCULATE ITS SCORE ###

my ( $input_sequence_score, $input_lowest_score, $input_n_w_lowest_score );
if ($seqtype eq 'DNA') {
    my @input_coding_sequence = unpack("(A3)*", $dnaseq);
    ( $input_sequence_score, $input_lowest_score, $input_n_w_lowest_score ) = Seqscore::score_sequence( \@input_coding_sequence, $sequence_lib );
} else {
    $input_sequence_score = 0;
    $input_lowest_score = 0;
    $input_n_w_lowest_score = 0;
}


### OPTIMIZE THE SEQUENCE ###

my $optimization_results = OptimizerTools::optimize($sequence_lib, $AAseq);


### OPTIONALLY ADD INTRONS ###

my $optseq_w_introns;
if ($add_introns) {
    $optseq_w_introns = OptimizerTools::addintrons( $optimization_results->{'Sequence'} );
}

### DISPLAY RESULTS ###

#Generate HTML page with results
my $appdir = $ENV{OPENSHIFT_REPO_DIR};
my $template = HTML::Template->new(filename => $appdir . 'libs/optimizer-results.tmpl');
$template->param(
        TITLE => ('Results for optimization of sequence "' . $seqname . '"'),
        DNA_INPUT => ($seqtype eq 'DNA'),
        INPUT_SEQ_SCORE => sprintf("%.1f", $input_sequence_score),
        INPUT_LOWEST_SCORE => sprintf("%.1f", $input_lowest_score),
        INPUT_N_W_LOWEST_SCORE => $input_n_w_lowest_score,
        RESULT_SEQ_SCORE => sprintf("%.1f", $optimization_results->{'Sequence_score'}),
        RESULT_LOWEST_SCORE => sprintf("%.1f", $optimization_results->{'Lowest_score'}),
        RESULT_N_W_LOWEST_SCORE => $optimization_results->{'Words_w_lowest_score'},
        INTRONS => $add_introns,
        OPT_SEQ => $optimization_results->{'Sequence'},
        OPT_SEQ_INTRONS => $optseq_w_introns,
);
print "Content-Type: text/html\n\n", $template->output;

