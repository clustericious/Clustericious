#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Mojo;

package Fake::Object::Thing;

sub new     { my $class = shift; bless { got => {@_} }, $class; }
sub save    { return 1; }
sub as_hash { return shift->{got} };

package Fake::Object;

sub find_class  {  return "Fake::Object::Thing";     }
sub find_object {  return Fake::Object::Thing->new() }

package SomeService;

use base 'Clustericious::App';
use Clustericious::RouteBuilder;
use Clustericious::RouteBuilder::CRUD
        "create" => { -as => "do_create" },
        defaults => { finder => "Fake::Object" };

post '/:table' => \&do_create;
get '/:items' => "noop";

package Rose::Planter;

sub tables {
    qw/one two three/;
}

sub plurals {
    qw/ones twos threes/;
}

package main;

my $t = Test::Mojo->new(app => "SomeService");

$t->post_form_ok("/my_table", { foo => "bar" }, {}, "posted to create")
    ->status_is(200, "got 200")
    ->json_content_is({foo => "bar"}, "got structure back");

$t->get_ok("/api")->text_is(<<API);
/one
/ones
/three
/threes
/two
/twos
API

1;


