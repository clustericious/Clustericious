use strict;
use warnings;
use File::HomeDir::Test;
use Test::More tests => 1;
use Test::Clustericious::Cluster;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( MyApp ));

__DATA__

@@ etc/MyApp.conf
---
url: <%= cluster->url %>

@@ lib/MyApp.pm
package MyApp;

use strict;
use warnings;
use Mojo::Base qw( Clustericious::App );
our $VERSION = '1.00';

1;
