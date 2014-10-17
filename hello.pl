#!/usr/bin/perl
use strict;
use warnings;

#use 5.010;
use CGI;

my $q = CGI->new();
say $q->header(), $q->start_html();

say "<h1>Parameters</h1>";

for my $param ($q->param()) {
    my $safe_param = $q->escapeHTML($param);

    say "<p><strong>$safe_param</strong>: ";

    for my $value ($q->param($param)) {
        say $q->escapeHTML($value);
    }

    say '</p>';
}

say $q->end_html();
