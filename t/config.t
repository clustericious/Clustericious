#!/usr/bin/env perl

use strict;
use warnings;

package SomeService;
use base 'Clustericious::App';
use Clustericious::RouteBuilder;
get '/' => sub { shift->render_text("hello"); };

package main;

use Test::More;
use Test::Mojo;
use File::Temp;

my $t = Test::Mojo->new('SomeService');

ok $t->app->config->isa('Clustericious::Config'),'got a config objects';

done_testing();


