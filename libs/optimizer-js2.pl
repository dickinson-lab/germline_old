#!/usr/bin/perl

use strict;
use warnings;

use 5.010;
use File::Pid;
use CGI::Carp qw(fatalsToBrowser);
use BerkeleyDB;
use Bio::Seq;
use Math::Random;
use JSON;
use Data::GUID;
use lib '/libs/';
use Seqscore;
use OptimizerTools;
    
#Get a unique id that parent and child will share
my $guid = Data::GUID->new;
my $id = $guid->as_hex;

my $pid = fork;

if (!defined $pid) {
    die "cannot fork: $!";
} elsif ($pid == 0) {
    # child does this
    close STDOUT;
    close STDERR;
    open STDERR, ">&=1";

    # Generate a PID file to allow progress monitoring
    my $appdir = $ENV{OPENSHIFT_REPO_DIR};
    my $tmpdir = $ENV{OPENSHIFT_TMP_DIR};
    my $pidloc = "$tmpdir" . "$id";
    my $pidfile = File::Pid->new({
        file => ($pidloc . '_running.pid')
    });
    $pidfile -> write;
    
    ### DO THE GERMLINE OPTIMIZATION ###
    
    ### Set Up ###
    
    my $error = '';
    
    # Get database
    my $datadir = $ENV{OPENSHIFT_DATA_DIR};
    my $sequence_lib = new BerkeleyDB::Btree
        -Filename => join('',$datadir,'sequence_lib_scores.db');
   
    # Get input
    my $q = CGI->new();
    my $userinput = decode_json($q->param('data'));
    my $seqname = $userinput->{'name'};
    my $dnaseq = $userinput->{'DNAseq'};
    my $AAseq = $userinput->{'AAseq'};
    my $seqtype = $userinput->{'seqtype'};
    my $add_introns = $userinput->{'add_introns'};

    my $results = {}; #Get a pointer to an empty array that will hold the results
    
    ### If a nucleotide sequence was entered, calculate its score ###
    
    my ( $input_sequence_score, $input_lowest_score, $input_n_w_lowest_score );
    if ($seqtype eq 'DNA') {
        my @input_coding_sequence = unpack("(A3)*", $dnaseq);
        ( $results->{'input_sequence_score'}, $results->{'input_lowest_score'}, $results->{'input_n_w_lowest_score'} ) = Seqscore::score_sequence( \@input_coding_sequence, $sequence_lib );
    } else {
        $results->{'input_sequence_score'} = 0;
        $results->{'input_lowest_score'} = 0;
        $results->{'input_n_w_lowest_score'} = 0;
    }
        
    ### Optimize the sequence ###
    
    my $optimization_results = OptimizerTools::optimize($sequence_lib, $AAseq);
    $results = {%$results, %$optimization_results};
    
    ### Optionally add introns ###
    
    my $optseq_w_introns;
    if ($add_introns) {
        $results->{'optseq_w_introns'} = OptimizerTools::addintrons( $optimization_results->{'Sequence'} );
    } else {
        $results->{'optseq_w_introns'} = '';
    }
    
    
    ### PRODUCE AN OUTPUT FILE TO BE READ BY THE PARENT ###
    
    # Save query parameters
    $results->{'name'} = $q->param('name');
    $results->{'seqtype'} = $seqtype;
    $results->{'introns'} = $add_introns;
    
    # Encode the file with JSON
    my $JSONresults = encode_json($results);        
    open OUTPUT, ">", $pidloc . '_results.dat';
    print OUTPUT $JSONresults;
    close OUTPUT;
    
    # Remove PID file to signal process completion
    $pidfile -> remove or warn "Couldn't unlink PID file\n";
    exit(0);
    
} else {
    # parent does this
    
    #Wait until PID file is created
    my $tmpdir = $ENV{OPENSHIFT_TMP_DIR};
    my $pidloc = "$tmpdir" . "$id";        
    until ( ( -e $pidloc . '_running.pid' ) || ( -e $pidloc . '_results.pid' ) ) {
        sleep 1;
    }
    
    #Return the location of the tmp files to the client
    print $pidloc;
}
