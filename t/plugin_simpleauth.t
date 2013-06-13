#!/usr/bin/env perl

use strict;
use warnings;
use autodie;
use v5.10;
use Test::More tests => 30;
use Test::Mojo;
use File::HomeDir::Test;
use File::HomeDir;
use YAML::XS qw( DumpFile );
use Mojo::URL;
use Mojo::Message::Response;

$ENV{LOG_LEVEL} = "ERROR";

package SomeService;

$SomeService::VERSION = '1.1';

use base 'Clustericious::App';
use Clustericious::RouteBuilder;

get '/' => sub { shift->render_text('hello'); };

authenticate;
authorize;

get '/private' => sub { shift->render_text('this is private'); };

package Fake::Tx;

sub new 
{
  my $class = shift;
  my $res = Mojo::Message::Response->new;
  $res->code(shift);
  bless { res => $res }, $class;
}

sub success { shift->{res} }
sub res { shift->{res} }

package main;

my $home = File::HomeDir->my_home;
mkdir "$home/etc";
DumpFile("$home/etc/SomeService.conf", {
  simple_auth => {
    url => 'http://simpleauth.test:1234',
  },
});

my $t = Test::Mojo->new("SomeService");

$t->get_ok('/')
  ->status_is(200)
  ->content_is('hello');

$t->get_ok('/private')
  ->status_is(401)
  ->content_is('auth required');

my $port = $t->ua->app_url->port;

$t->get_ok("http://foo:bar\@localhost:$port/private")
  ->status_is(503)
  ->content_is('auth server down');

# TODO tests for successful auth

my $status = {};

do {
  my $old_get = \&Mojo::UserAgent::get;
  my $new_get = sub {
    my($self, $url, @rest) = @_;
    $url = Mojo::URL->new($url);
    if($url->host eq 'simpleauth.test' && $url->path eq '/host/127.0.0.1/trusted') {
      Fake::Tx->new($status->{trusted});
    } else {
      $old_get->(@_);
    }
  };
  no warnings 'redefine';
  *Mojo::UserAgent::get = $new_get;
};

do {
  my $old_head = \&Mojo::UserAgent::head;
  my $new_head = sub {
    my($self, $url, @rest) = @_;
    $url = Mojo::URL->new($url);
    if($url->host eq 'simpleauth.test' && $url->path eq '/auth') {
      Fake::Tx->new($status->{auth});
    } elsif($url->host eq 'simpleauth.test' && $url->path =~ m{^/authz}) {
      Fake::Tx->new($status->{authz});
    } else {
      $old_head->(@_);
    }
  };
  no warnings 'redefine';
  *Mojo::UserAgent::head = $new_head;
};

# not trusted, auth good and authorized.
$status = { 
  trusted => 403,
  auth    => 200,
  authz   => 200,
};

$t->get_ok("http://foo:bar\@localhost:$port/private")
  ->status_is(200)
  ->content_is('this is private');

# trusted, auth bad, and authorized
$status = {
  trusted => 200,
  auth    => 401,
  authz   => 200,
};

$t->get_ok("http://foo:bar\@localhost:$port/private")
  ->status_is(200)
  ->content_is('this is private');

# trusted, auth bad, and authorized
$status = {
  trusted => 200,
  auth    => 403,
  authz   => 200,
};

$t->get_ok("http://foo:bar\@localhost:$port/private")
  ->status_is(200)
  ->content_is('this is private');

# not trusted, simpleauth returned 503
$status = {
  trusted => 403,
  auth    => 503,
  authz   => 200,
};

$t->get_ok("http://foo:bar\@localhost:$port/private")
  ->status_is(503)
  ->content_is('auth server down');

# not trusted, authenticated, but simpleauth returned 503 for authz
$status = {
  trusted => 403,
  auth    => 200,
  authz   => 503,
};

$t->get_ok("http://foo:bar\@localhost:$port/private")
  ->status_is(503)
  ->content_is('auth server down');

# not trusted, authenticated, but not authorized
$status = {
  trusted => 403,
  auth    => 200,
  authz   => 403,
};

$t->get_ok("http://foo:bar\@localhost:$port/private")
  ->status_is(403)
  ->content_is('unauthorized');

# not trusted, auth returned 403
$status = {
  trusted => 403,
  auth    => 403,
  authz   => 200,
};

$t->get_ok("http://foo:bar\@localhost:$port/private")
  ->status_is(401)
  ->content_is('authentication failure');

1;
