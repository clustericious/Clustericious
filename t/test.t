#!/usr/bin/env perl
#
# Yes.  This is the test for the test...
#
use strict;
use warnings;

use Test::More 'no_plan';
use Test::Clustericious;
use Mojo::JSON;

package SomeService;

use base 'Clustericious::App';
use Clustericious::RouteBuilder;

my $object;

get    '/object/id' => sub { my $c = shift;
                             if ($object) { $c->render_json($object) }
                             else { $c->res->code(404);
                                    $c->render_text('Not Found') } };

post   '/object'    => sub { my $c = shift;
                             $c->app->plugins->run_hook('parse_data', $c);
                             $object = $c->stash->{data};
                             $c->render_json($object) };

Delete '/object/id' => sub { my $c = shift;
                             $object = undef;
                             $c->render_text('ok') };

package main;

my $t = new_ok('Test::Clustericious', [ app => "SomeService" ]);

my $test_obj = { a => 'b', c => 'd' };

my $x = $t->create_ok('/object', $test_obj);

is_deeply($x, $test_obj, 'Check created object = sent object');

$x = $t->retrieve_ok('/object/id');

is_deeply($x, $test_obj, 'Check retrieved object = created object');

$t->remove_ok('/object/id');

$t->notfound_ok('/object/id');

$test_obj = $t->testdata('testobject');

$x = $t->create_ok('/object', 'testobject');

is_deeply($x, $test_obj, 'Check uploading object from a file');

$x = $t->retrieve_ok('/object/id');

is_deeply($x, $test_obj, 'Check retrieved object = object from file');

1;
