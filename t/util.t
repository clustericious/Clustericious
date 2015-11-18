use strict;
use warnings;
use Test::More tests => 1;
use Clustericious;

my $pid = Clustericious::_slurp_pid 't/util.pid';
is $pid, 42;
