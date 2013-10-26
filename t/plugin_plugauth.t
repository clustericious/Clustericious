use strict;
use warnings;
use autodie;
use v5.10;
use Test::Clustericious::Config;
use Test::More tests => 31;
use Test::Mojo;
use Test::PlugAuth;

$ENV{LOG_LEVEL} = "ERROR";

my $status = {};

my $auth = Test::PlugAuth->new(
  auth  => sub { $status->{auth}  // die },
  authz => sub { $status->{authz} // die },
  host  => sub { $status->{host}  // die },
);

eval q{
  package SomeService;

  our $VERSION = '1.1';
  use base 'Clustericious::App';

  package SomeService::Routes;

  use Clustericious::RouteBuilder;

  get '/' => sub { shift->render_text('hello'); };

  authenticate;
  authorize;

  get '/private' => sub { shift->render_text('this is private'); };
};
die $@ if $@;

my $prefix = 'plug';

create_config_ok SomeService => {
  "${prefix}_auth" => {
    url => $auth->url,
  },
};

#note "GET $auth_url/auth";
#note $auth_ua->get("$auth_url/auth")->res->to_string;

my $t = Test::Mojo->new("SomeService");
$auth->apply_to_client_app($t->app);

note ' request 01 ';

$t->get_ok('/')
  ->status_is(200)
  ->content_is('hello');

note ' request 02 ';
  
$t->get_ok('/private')
  ->status_is(401)
  ->content_is('auth required');

my $port = eval { $t->ua->server->url->port; } // $t->ua->app_url->port;

note ' request 03 ';

$t->get_ok("http://foo:bar\@localhost:$port/private")
  ->status_is(503)
  ->content_is('auth server down');

# not trusted, auth good and authorized.
$status = { 
  trusted => 0,
  auth    => 1,
  authz   => 1,
};

note ' request 04 ';

$t->get_ok("http://foo:bar\@localhost:$port/private")
  ->status_is(200)
  ->content_is('this is private');

SKIP: {
  skip 'skip broken tests', 6;
  # trusted, auth bad, and authorized
  $status = {
    trusted => 1,
    auth    => 0,
    authz   => 1,
  };

  note ' request 05 ';

  $t->get_ok("http://foo:bar\@localhost:$port/private")
    ->status_is(200)
    ->content_is('this is private');

  # trusted, auth bad, and authorized
  $status = {
    trusted => 1,
    auth    => 0,
    authz   => 1,
  };

  note ' request 06 ';

  $t->get_ok("http://foo:bar\@localhost:$port/private")
    ->status_is(200)
    ->content_is('this is private');
}

# not trusted, PlugAuth returned 503
$status = {
  trusted => 0,
  auth    => undef,
  authz   => 1,
};

note ' request 07 ';

$t->get_ok("http://foo:bar\@localhost:$port/private")
  ->status_is(503)
  ->content_is('auth server down');

# not trusted, authenticated, but PlugAuth returned 503 for authz
$status = {
  trusted => 0,
  auth    => 1,
  authz   => undef,
};

note ' request 08 ';

$t->get_ok("http://foo:bar\@localhost:$port/private")
  ->status_is(503)
  ->content_is('auth server down');

# not trusted, authenticated, but not authorized
$status = {
  trusted => 0,
  auth    => 1,
  authz   => 0,
};

note ' request 09 ';

$t->get_ok("http://foo:bar\@localhost:$port/private")
  ->status_is(403)
  ->content_is('unauthorized');

# not trusted, auth returned 403
$status = {
  trusted => 0,
  auth    => 0,
  authz   => 1,
};

note ' request 10 ';

$t->get_ok("http://foo:bar\@localhost:$port/private")
  ->status_is(401)
  ->content_is('authentication failure');

1;
