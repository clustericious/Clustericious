#!perl

package main;
use Test::More;
use IO::Scalar;
use Clustericious::Commands;

use strict;

BEGIN {
    $ENV{LOG_LEVEL} = 'FATAL';
}

my $c;
{
    local $ENV{HARNESS_ACTIVE};
    tie *STDOUT, 'IO::Scalar', \$c;
    Clustericious::Commands->new->run('generate');
    untie *STDOUT;
}

like $c, qr/mbd_app/, 'help text has mbd_app';

done_testing();

