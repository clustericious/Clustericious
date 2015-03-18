use strict;
use warnings;
use Test::More tests => 1;
use Clustericious::Util qw( slurp_pid );

my $pid = slurp_pid 't/util.pid';
is $pid, 42;
