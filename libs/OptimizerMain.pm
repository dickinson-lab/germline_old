#!/usr/bin/perl

# To Do: Add more checks to validate user input.

package OptimizerMain;

use strict;
use warnings;

use 5.010;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Redirect;
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

sub start_optimization : StartRunmode {
    my $self = shift;
    
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
        
        # Get CGI query
        my $q = $self->query();
       
        # Get input
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
        return "Content-Type: text/html\n\n", $id;
    }

}


sub optimizer_status : Runmode {
    my $self = shift;
    
    # Get ready to access PID file
    my $q = $self->query();
    my $id = $q->param('id');
    my $tmpdir = $ENV{OPENSHIFT_TMP_DIR};
    my $datadir = $ENV{OPENSHIFT_DATA_DIR};
    my $appdir = $ENV{OPENSHIFT_REPO_DIR};
    my $pidloc = "$tmpdir" . "$id";
    
    my $pidfile = File::Pid->new({
        file => $pidloc . '_running.pid'
    });
    
    # Check if process is still running
    my $still_running = 0;
    if ( -e $pidloc . '_running.pid' ) {
        if ( $pidfile -> running ) {
            $still_running = 1;
        } else {
            $still_running = 0;
        }
    }
    
    # Report status, and results if finished
    my $response = {};
    if ($still_running) {
        $response->{'status'} = 'working';
    } else {
        $response->{'status'} = 'complete';
        
        # Load result file
        open RESULTS, "<", $pidloc . '_results.dat' or die "Program error: Couldn't open results file";
        my $JSONresults = <RESULTS>;
        close RESULTS;
        my $results = decode_json($JSONresults);  # $results now contains a pointer to the results of optimization
        
        #G enerate HTML page with results
        my $template = $self->load_tmpl($appdir . 'optimizer-results.html');
        $template->param(
                TITLE => ('Results for optimization of sequence "' . $results->{'name'} . '"'),
                DNA_INPUT => ($results->{'seqtype'} eq 'DNA'),
                INPUT_SEQ_SCORE => sprintf("%.1f", $results->{'input_sequence_score'}),
                INPUT_LOWEST_SCORE => sprintf("%.1f", $results->{'input_lowest_score'}),
                INPUT_N_W_LOWEST_SCORE => $results->{'input_n_w_lowest_score'},
                RESULT_SEQ_SCORE => sprintf("%.1f", $results->{'Sequence_score'}),
                RESULT_LOWEST_SCORE => sprintf("%.1f", $results->{'Lowest_score'}),
                RESULT_N_W_LOWEST_SCORE => $results->{'Words_w_lowest_score'},
                INTRONS => $results->{'introns'},
                OPT_SEQ => $results->{'Sequence'},
                OPT_SEQ_INTRONS => $results->{'optseq_w_introns'},
        );
        $response->{'htmlOut'} = $template->output;
    }
    # Return the results
    my $JSONresponse = encode_json($response);
    return $JSONresponse;
}

sub optimizer_results : Runmode {
    my $self = shift;
    
    # Load result file
    my $q = $self->query();
    my $id = $q->param('id');
    my $tmpdir = $ENV{OPENSHIFT_TMP_DIR};
    my $pidloc = "$tmpdir" . "$id";
    open RESULTS, "<", $pidloc . '_results.dat' or die "Program error: Couldn't open results file";
    my $JSONresults = <RESULTS>;
    close RESULTS;
    my $results = decode_json($JSONresults);  # $results now contains a pointer to the results of optimization
    
    #Generate HTML page with results
    my $appdir = $ENV{OPENSHIFT_REPO_DIR};
    my $template = $self->load_tmpl($appdir . 'optimizer-results.html');
    $template->param(
            TITLE => ('Results for optimization of sequence "' . $results->{'name'} . '"'),
            DNA_INPUT => ($results->{'seqtype'} eq 'DNA'),
            INPUT_SEQ_SCORE => sprintf("%.1f", $results->{'input_sequence_score'}),
            INPUT_LOWEST_SCORE => sprintf("%.1f", $results->{'input_lowest_score'}),
            INPUT_N_W_LOWEST_SCORE => $results->{'input_n_w_lowest_score'},
            RESULT_SEQ_SCORE => sprintf("%.1f", $results->{'Sequence_score'}),
            RESULT_LOWEST_SCORE => sprintf("%.1f", $results->{'Lowest_score'}),
            RESULT_N_W_LOWEST_SCORE => $results->{'Words_w_lowest_score'},
            INTRONS => $results->{'introns'},
            OPT_SEQ => $results->{'Sequence'},
            OPT_SEQ_INTRONS => $results->{'optseq_w_introns'},
    );
    return $template->output;
}

1;
