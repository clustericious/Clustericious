use strict;
use warnings;
eval q{ use Test::Clustericious::Log };
use Test::More tests => 1;
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


