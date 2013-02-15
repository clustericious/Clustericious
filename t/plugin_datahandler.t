#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;

use Test::More tests => 40;
use Test::Mojo;

package Fake::Object::Thing;

my $persist;  # Always find the last one created

sub new     { my $class = shift; $persist = bless { got => {@_} }, $class; }
sub save    { return 1; }
sub load    { 1; }
sub as_hash { return shift->{got} };

package Fake::Object;

sub find_class  {  return "Fake::Object::Thing";     }
sub find_object {  return $persist or Fake::Object::Thing->new() }

package SomeService;

use base 'Clustericious::App';
use Clustericious::RouteBuilder;
use Clustericious::RouteBuilder::CRUD
        "read"   => { -as => "do_read" },
        "create" => { -as => "do_create" },
        defaults => { finder => "Fake::Object" };

post '/:table'        => \&do_create;
get  '/:table/(*key)' => \&do_read;

package main;

my $t = Test::Mojo->new("SomeService");

$t->post_ok("/my_table", form => { foo => "bar" }, {}, "posted to create")
    ->status_is(200, "got 200")
    ->header_is('Content-Type' => 'application/json')
    ->json_content_is({foo => "bar"}, "got structure back");

$t->get_ok('/my_table/foo',
           { Accept => 'application/json' },
           '', "get json")
  ->status_is(200, "got 200")
  ->header_is('Content-Type' => 'application/json')
  ->json_content_is({foo => "bar"}, "got structure back in JSON");

$t->get_ok('/my_table/foo',
           { Accept => 'application/bogus;q=0.8,application/json' },
           '', "ignore bogus accept, still get json")
  ->status_is(200, "got 200")
  ->header_is('Content-Type' => 'application/json')
  ->json_content_is({foo => "bar"}, "got structure back in JSON");

$t->get_ok('/my_table/foo',
           { Accept => 'application/bogus;q=0.8' },
           '', "ignore bogus accept, still get json by default")
  ->status_is(200, "got 200")
  ->header_is('Content-Type' => 'application/json')
  ->json_content_is({foo => "bar"}, "got structure back in JSON");

$t->get_ok('/my_table/foo',
           { Accept => 'text/x-yaml' },
           '', "get yaml by accept")
  ->status_is(200, "got 200")
  ->header_is('Content-Type' => 'text/x-yaml')
  ->content_is("---\nfoo: bar\n", "got structure back in YAML");

$t->get_ok('/my_table/foo',
           { 'Content-Type' => 'text/x-yaml' }, 
           '', "get yaml by Content-Type")
  ->status_is(200, "got 200")
  ->header_is('Content-Type' => 'text/x-yaml')
  ->content_is("---\nfoo: bar\n", "got structure back in YAML");

$t->post_ok("/my_table",
            json => { foo => 'bar' },
            "Post json")
    ->status_is(200, "got 200")
    ->header_is('Content-Type' => 'application/json')
    ->json_content_is({foo => "bar"}, "got structure back");

$t->get_ok('/my_table/foo',
           { Accept => 'text/x-yaml' },
           '', "get yaml by accept")
  ->status_is(200, "got 200")
  ->header_is('Content-Type' => 'text/x-yaml')
  ->content_is("---\nfoo: bar\n", "got structure back in YAML");

$t->post_ok("/my_table", json => { foo => 'bar' },
            { Accept => 'application/json',
              'Content-Type' => 'text/x-yaml' },
            "Post json")
    ->status_is(200, "got 200")
    ->header_is('Content-Type' => 'application/json')
    ->json_content_is({foo => "bar"}, "got structure back");

$t->get_ok('/my_table/foo',
           '', "get json")
  ->status_is(200, "got 200")
  ->header_is('Content-Type' => 'application/json')
  ->json_content_is({foo => "bar"}, "got structure back");

1;
