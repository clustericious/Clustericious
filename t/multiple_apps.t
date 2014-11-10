use strict;
use warnings;
use 5.010;
use Test::Clustericious::Config;
use Test::Clustericious;
use Test::More tests => 6;

create_config_ok 'Clustericious::HelloWorld' => { x => 1, y => 2 };

my $t1 = Test::Clustericious->new('Clustericious::HelloWorld');

$t1->get_ok('/');

is $t1->app->config->x, 1, 't.app.config.x = 1';

create_config_ok 'Clustericious::HelloWorld' => { x => 3, y => 4 };

my $t2 = Test::Clustericious->new('Clustericious::HelloWorld');

$t2->get_ok('/');

is $t2->app->config->x, 3, 't.app.config.x = 3';

