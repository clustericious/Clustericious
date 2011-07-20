#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Mojo;

package SomeService;

$SomeService::VERSION = '867.5309';

use base 'Clustericious::App';
use Clustericious::RouteBuilder;

get '/' => sub { shift->render_text("hello"); };

package main;

my $t = Test::Mojo->new("SomeService");

$t->get_ok("/")->status_is(200)->content_like(qr/hello/, "got content");

$t->get_ok('/version')
    ->status_is(200,'GET /version')
    ->json_content_is([$SomeService::VERSION], '/version is correct');

1;


