use strict;
use warnings;
use Test::More tests => 3;
use Test::Clustericious::Cluster;

Test::Clustericious::Cluster->extract_data_section;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Foo Foo Bar ));

subtest isa => sub {
  plan tests => 4;
  isa_ok $cluster->apps->[0]->client, 'Clustericious::Client';
  isa_ok $cluster->apps->[1]->client, 'Clustericious::Client';
  isa_ok $cluster->apps->[2]->client, 'Clustericious::Client';
  isa_ok $cluster->apps->[2]->client, 'Bar::Client';
};

note "url[0] = @{[ $cluster->apps->[0]->client->config->url ]}";
note "url[1] = @{[ $cluster->apps->[1]->client->config->url ]}";
note "url[2] = @{[ $cluster->apps->[2]->client->config->url ]}";

subtest 'sans client class' => sub {
  plan skip_all => 'borked for now';

  my $client = $cluster->apps->[0]->client;
  is $client->status->{version}, '1.23';

};

__DATA__

@@ etc/Foo.conf
---
url: <%= cluster->url %>
index: <%= cluster->index %>


@@ lib/Foo.pm
package Foo;

our $VERSION = '1.23';

use strict;
use warnings;
use base qw( Clustericious::App );

1;


@@ lib/Bar.pm
package Bar;

our $VERSION = '4.56';

use strict;
use warnings;
use base qw( Clustericious::App );

1;


@@ lib/Bar/Client.pm
package Bar::Client;

use strict;
use warnings;
use Clustericious::Client;

1;
