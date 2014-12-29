use strict;
use warnings;
use Test::Clustericious::Log;
use Test::More tests => 14;
use Test::Mojo;

package SomeService;

$SomeService::VERSION = '867.5309';

use base 'Clustericious::App';
use Clustericious::RouteBuilder;

get '/' => sub { shift->render_text("hello"); };

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

# trying to get meta data for a bogus table should not
# return 500 when Rose::Planter is not loaded.
$t->get_ok('/api/bogus_table')
    ->status_is(404);

$t->get_ok('/api')
    ->status_is(200);

1;
