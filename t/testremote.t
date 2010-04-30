#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Clustericious;

SKIP: {
    skip 'Skipping remote tests because CLUSTERICIOUSTESTURL not set', 4 
         if not defined $ENV{CLUSTERICIOUSTESTURL};

    my $t = new_ok('Test::Clustericious', 
                   [ server_url => $ENV{CLUSTERICIOUSTESTURL} ]);

    my $x = $t->retrieve_ok('/');

    like($x, qr/welcome/i, "Got a welcome message");
}

1;
