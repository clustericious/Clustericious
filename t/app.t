#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Mojo;

package SomeService;

use base 'Clustericious::App';
use Clustericious::RouteBuilder;

get '/' => sub { shift->render_text("hello"); };

package main;

my $t = Test::Mojo->new(app => "SomeService");

$t->get_ok("/")->status_is(200)->content_like(qr/hello/, "got content");

1;


