use strict;
use warnings;
use Test::Clustericious::Log;
use Test::More tests => 21;
use Test::Mojo;

package SomeService;

$SomeService::VERSION = '867.5309';

use base 'Clustericious::App';
use Clustericious::RouteBuilder;

get '/' => sub { shift->render_text("hello"); };

get '/autotest' => sub { shift->stash->{autodata} = { a => 1, b => 2 } };

get '/autotest_not_found' => sub {
  my($self) = shift;
  $self->stash->{autodata} = [1,2,3];
  $self->reply->not_found;
};

package main;

use YAML::XS qw( Load );

my $t = Test::Mojo->new("SomeService");

$t->get_ok("/")->status_is(200)->content_like(qr/hello/, "got content");

$t->get_ok('/version')
    ->status_is(200,'GET /version')
    ->json_is('', [$SomeService::VERSION], '/version is correct');

$t->get_ok('/version.yml')
    ->status_is(200, 'GET /version.yml')
    ->header_is('Content-Type', 'text/x-yaml');

is eval { Load($t->tx->res->body)->[0] }, $SomeService::VERSION, '/version.yml is correct';
diag $@ if $@;

note $t->tx->res->body;

# trying to get meta data for a bogus table should not
# return 500 when Rose::Planter is not loaded.
$t->get_ok('/api/bogus_table')
    ->status_is(404);

$t->get_ok('/api')
    ->status_is(200);

$t->get_ok('/autotest')
  ->status_is(200)
  ->json_is({ a => 1, b => 2 });

SKIP: {
  skip 'skip test broken by Mojo 6.32', 2 if $ENV{CLUSTERICIOUS_SKIP_BORKED};
  $t->get_ok('/autotest.yml')
    ->status_is(200);
  note $t->tx->res->text;
};

$t->get_ok('/autotest_not_found')
  ->status_is(404);
note $t->tx->res->text;
