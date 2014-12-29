use strict;
use warnings;

my $ok;
BEGIN {
   eval "use Clustericious::App";
   $ok = 1 unless $@;
}

use Test::More $ok ? (tests => 7) : ( skip_all => "No Clustericious::App" );

Log::Log4perl->easy_init(level => "WARN");

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

get  '/'              => sub { shift->render_text('welcome') };
post '/:table'        => \&do_create;
get  '/:table/(*key)' => \&do_read;

package SomeClient;

use Clustericious::Client;

route 'welcome' => '/';
route_doc 'welcome' => "Say hello";
route_meta 'welcome' => { jambo => 'sana' };
route 'broken' => '/borked';

object 'foo';

package main;

my $client = SomeClient->new(app => 'SomeService');

is($client->welcome(), 'welcome', 'Got welcome route');

my $test_obj = { a => 'b' };

is_deeply($client->foo($test_obj), $test_obj, 'Create object');

is_deeply($client->foo('a'), $test_obj, 'Retrieve object');

is($client->meta_for("welcome")->get("jambo"), "sana", "Set metadata");

is($client->meta_for("welcome")->doc, "Say hello", "Set metadata");

is($client->broken, undef, 'client.broken');
is $client->errorstring, '(404) Not Found', 'client.errormessage';

1;
