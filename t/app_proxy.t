use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 10;

my $cluster = Test::Clustericious::Cluster
  ->new
  ->create_cluster_ok('SomeService');
my $t = $cluster->t;

my $got =
  $t->get_ok( '/proxyme/here')
  ->content_is( "you made it", 'proxy had right content' )->status_is(200);

$t->post_ok( '/proxyme/here')
  ->content_is( "you made it too", 'proxy had right content' )->status_is(200);

$t->delete_ok( '/proxyme/here')
  ->content_is( "you made it three", 'proxy had right content' )->status_is(200);

__DATA__

@@ lib/SomeService.pm
package SomeService;

use base 'Clustericious::App';
use Clustericious::RouteBuilder;
use Clustericious::RouteBuilder::Proxy
  "proxy" => { -as => "local_proxy", to => 'localhost', strip_prefix => '/proxyme' };

get '/proxyme/here' => \&local_proxy;
post '/proxyme/here' => \&local_proxy;
any '/proxyme/here' => \&local_proxy;
get '/here' => sub { shift->render(text => "you made it") };
post '/here' => sub { shift->render(text => "you made it too") };
del '/here' => sub { shift->render(text => "you made it three") };

1;


