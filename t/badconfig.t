use strict;
use warnings;
eval q{ use Test::Clustericious::Log diag => 'NONE' };
die $@ if $@;
use File::HomeDir::Test;
use Test::More tests => 1;
use Test::Clustericious::Cluster;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Foo ));

__DATA__

@@ lib/Foo.pm
package Foo;

use strict;
use warnings;
use Mojo::Base qw( Clustericious::App );
our $VERSION = '1.00';

1;

@@ etc/Foo.conf
---
badly formed
yaml should die
