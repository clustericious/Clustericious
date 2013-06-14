use strict;
use warnings;
use autodie;
use v5.10;
use Test::More tests => 30;
use Test::Mojo;
use File::HomeDir::Test;
use File::HomeDir;
use YAML::XS qw( DumpFile );
use PlugAuth::Lite;

$ENV{LOG_LEVEL} = "ERROR";

my $status = {};

my $auth_ua = Mojo::UserAgent->new;
$auth_ua->app(
  PlugAuth::Lite->new({
    auth  => sub { $status->{auth}  // die },
    authz => sub { $status->{authz} // die },
    host  => sub { $status->{host}  // die },
  })
);
note ".t ua = $auth_ua";

package SomeService;

$SomeService::VERSION = '1.1';
use base 'Clustericious::App';

sub startup
{
  my $self = shift;
  $self->SUPER::startup;
  $self->helper(auth_ua => sub { $auth_ua });
};

package SomeService::Routes;

use Clustericious::RouteBuilder;

get '/' => sub { shift->render_text('hello'); };

authenticate;
authorize;

get '/private' => sub { shift->render_text('this is private'); };

package main;

my $prefix = 'simple';

my $home = File::HomeDir->my_home;
my $auth_url = $auth_ua->app_url->to_string;
$auth_url =~ s{/$}{};
mkdir "$home/etc";
DumpFile("$home/etc/SomeService.conf", {
  "${prefix}_auth" => {
    url => $auth_url,
  },
});

note do {
  local $/;
  open my $fh, '<', "$home/etc/SomeService.conf";
  my $data = <$fh>;
  close $fh;
  $data;
};

note "GET $auth_url/auth";
note $auth_ua->get("$auth_url/auth")->res->to_string;

my $t = Test::Mojo->new("SomeService");

note ' request 01 ';

$t->get_ok('/')
  ->status_is(200)
  ->content_is('hello');

note ' request 02 ';
  
$t->get_ok('/private')
  ->status_is(401)
  ->content_is('auth required');

my $port = $t->ua->app_url->port;

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
