use strict;
use warnings;
use 5.010;
use Test::Clustericious::Cluster;
use Test::More tests => 5;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Clustericious::HelloWorld Clustericious::HelloWorld ));
my $t = $cluster->t;

$t->get_ok($cluster->urls->[0]);

is $cluster->apps->[0]->config->x, 1;

$t->get_ok($cluster->urls->[1]);

is $cluster->apps->[1]->config->x, 3;


=pod

my $t1 = Test::Clustericious->new('Clustericious::HelloWorld');

$t1->get_ok('/');

is $t1->app->config->x, 1, 't.app.config.x = 1';

create_config_ok 'Clustericious::HelloWorld' => { x => 3, y => 4 };

my $t2 = Test::Clustericious->new('Clustericious::HelloWorld');

$t2->get_ok('/');

is $t2->app->config->x, 3, 't.app.config.x = 3';

=cut

__DATA__

@@ etc/Clustericious-HelloWorld.conf
---
x: <%= cluster->index == 0 ? 1 : 3 %>
y: <%= cluster->index == 0 ? 2 : 4 %>
