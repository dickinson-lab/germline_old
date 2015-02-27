#!/usr/bin/perl
use strict;
use warnings;

use 5.010;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Bio::Seq;
use HTML::Template;
use JSON;

# To do next: Pass data as a JSON-encoded string instead of individual parameters.
# See http://stackoverflow.com/questions/17810063/jquery-ajax-post-huge-string-value

# Get input
our $q = CGI->new();
my %userinput;
my $in_name = $q->param('name');
$userinput{name} = $q->escapeHTML($in_name);
my $inseq = $q->param('sequence');
my $safeseq = $q->escapeHTML($inseq);
$safeseq =~ s/\s+//g; #Remove whitespace
$userinput{seqtype} = $q->param('seq_type');
$userinput{add_introns} = $q->param('introns');

# Check sequence for invalid characters
my $bio_seq = Bio::Seq->new();

if ( ! $bio_seq->validate_seq($safeseq) ) {
    error("You entered an invalid sequence");
}

# If sequence is ok, make a Bio::Seq object out of it
my $seqobj = Bio::Seq->new( -seq => $safeseq );

# Check sequence for correct type, generate amino acid sequence
if ($userinput{seqtype} eq 'AA') {
    if ( $seqobj->alphabet ne 'protein' ) {
        error("You selected \"Amino Acid,\" but your input doesn't appear to be an amino acid sequence. Please check the sequence and try again.");
    }
    $userinput{DNAseq} = '';
    $userinput{AAseq} = $seqobj->seq();
} elsif ($userinput{seqtype} eq 'DNA') {
    
    if ( $seqobj->alphabet ne 'dna') {
        error("You selected \"DNA,\" but your input doesn't appear to be a nucleotide sequence. Please check the sequence and try again.");
    }
    my $trans = $seqobj->translate();
    $userinput{AAseq} = $trans->seq();
    $userinput{DNAseq} = $seqobj->seq();
} else {
    error("Program error :-\("); #You'd only get this if the HTML form returned the wrong value.
}

# Generate page to launch optimizer
my $appdir = $ENV{OPENSHIFT_REPO_DIR};
my $JSONinput = encode_json(\%userinput);
my $template = HTML::Template->new(filename => $appdir . 'libs/optimizer-runpage.tmpl');
$template->param(INPUT => $JSONinput);
print "Content-Type: text/html\n\n", $template->output;


sub error {
    my $errormsg = shift;
    say $q->header(), $q->start_html();
    say("<h2>Error</h2>");
    say("<p>$errormsg</p>");
    say $q->end_html();
    exit;
}