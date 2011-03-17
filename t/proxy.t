#!/usr/bin/env perl

use strict;
use warnings;

use Test::More qw/no_plan/;
use Test::Mojo;

package SomeService;

use base 'Clustericious::App';
use Clustericious::RouteBuilder;
use Clustericious::RouteBuilder::Proxy
  "proxy" => { -as => "local_proxy", to => 'localhost', strip_prefix => '/proxyme' };

get '/proxyme/here' => \&local_proxy;
get '/here' => sub { sleep 5; shift->render_text("you made it") };

package main;

my $t = Test::Mojo->new(app => "SomeService");

my $got =
$t->get_ok('/proxyme/here', '', 'got proxy url')->content_is("you made it",'proxy had right content')->status_is(200);

1;

