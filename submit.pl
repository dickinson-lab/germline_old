#!/usr/bin/perl
use strict;
use warnings;

use 5.010;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Bio::Seq;
use HTML::Template;

# Get input
my $q = CGI->new();
my $in_name = $q->param('name');
my $safename = $q->escapeHTML($in_name);
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
my $DNAseq = '';
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
    $DNAseq = $seqobj->seq();
} else {
    error("Program error :-\("); #You'd only get this if the HTML form returned the wrong value.
}

# Generate page to launch optimizer
my $appdir = $ENV{OPENSHIFT_REPO_DIR};
my $template = HTML::Template->new(filename => $appdir . 'libs/optimizer-runpage.tmpl');
$template->param(
    SEQ_NAME => $safename;
    DNA_SEQ => $DNAseq;
    AA_SEQ => $AAseq;
    SEQ_TYPE => $seqtype;
    INTRONS => $add_introns;
);
print "Content-Type: text/html\n\n", $template->output;


sub error {
    my $errormsg = shift;
    say $q->header(), $q->start_html();
    say("<h2>Error</h2>");
    say("<p>$errormsg</p>");
    say $q->end_html();
    exit;
}