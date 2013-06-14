use strict;
use warnings;
use v5.10;
use Test::Clustericious::Config;
use Test::Clustericious;
use Test::More tests => 6;

create_config_ok 'Clustericious::HelloWorld' => { x => 1, y => 2 };

my $t = Test::Clustericious->new('Clustericious::HelloWorld');

$t->get_ok('/');

is $t->app->config->x, 1, 't.app.config.x = 1';

create_config_ok 'Clustericious::HelloWorld' => { x => 3, y => 4 };

my $t2 = Test::Clustericious->new('Clustericious::HelloWorld');

$t2->get_ok('/');

is $t2->app->config->x, 3, 't.app.config.x = 3';
