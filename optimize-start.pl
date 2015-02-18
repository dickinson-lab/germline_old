#!/usr/bin/perl
use strict;
use warnings;

use 5.010;
use CGI::Carp qw(fatalsToBrowser);
use Data::GUID;
use lib '/libs/';
use OptimizerMain;

#Get a unique id for this session
my $guid = Data::GUID->new;
my $id = $guid->as_hex;

#Launch application
my $webapp = OptimizerMain -> new(
                PARAMS => {'id' => $id}
                );
$webapp->run();