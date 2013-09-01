#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Mojo;

package SomeService;

use base 'Clustericious::App';
use Clustericious::RouteBuilder;
use Clustericious::RouteBuilder::Proxy
  "proxy" => { -as => "local_proxy", to => 'localhost', strip_prefix => '/proxyme' };

get '/proxyme/here' => \&local_proxy;
post '/proxyme/here' => \&local_proxy;
any '/proxyme/here' => \&local_proxy;
get '/here' => sub { sleep 2; shift->render_text("you made it") };
post '/here' => sub { sleep 2; shift->render_text("you made it too") };
del '/here' => sub { shift->render_text("you made it three") };

package main;

my $t = Test::Mojo->new("SomeService");

my $got =
  $t->get_ok( '/proxyme/here', '', 'got proxy url' )
  ->content_is( "you made it", 'proxy had right content' )->status_is(200);

$t->post_ok( '/proxyme/here', '', 'got proxy url' )
  ->content_is( "you made it too", 'proxy had right content' )->status_is(200);

$t->delete_ok( '/proxyme/here', '', 'got proxy url' )
  ->content_is( "you made it three", 'proxy had right content' )->status_is(200);

done_testing;

1;

