use strict;
use warnings;
use Test::Clustericious::Log;
use Test::More tests => 7;
use Test::Mojo;

package Fake::Object::Thing;

sub new     { my $class = shift; bless { got => {@_} }, $class; }
sub save    { return 1; }
sub load    { return 1; }
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

authenticate;

authorize 'foo';

post '/:table' => \&do_create;
get '/:items' => "noop";

package Rose::Planter;

no warnings 'redefine';

sub tables {
    qw/one two three/;
}

sub plurals {
    qw/ones twos threes/;
}

package main;

my $t = Test::Mojo->new("SomeService");

$t->post_ok("/my_table", form => { foo => "bar" }, {}, "posted to create")
    ->status_is(200, "got 200")
    ->json_is('', {foo => "bar"}, "got structure back");

$t->get_ok("/api")->json_is('',
    [
        "GET /api",
        "GET /api/one",
        "GET /api/three",
        "GET /api/two",
        "GET /log/:lines",
        "GET /ones",
        "GET /status",
        "GET /threes",
        "GET /twos",
        "GET /version",
        "OPTIONS /*opturl",
        "POST /one",
        "POST /three",
        "POST /two"
]);

$t->get_ok('/log/1')->content_is("logs not available");

1;


