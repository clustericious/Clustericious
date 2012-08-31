#!/usr/bin/env perl

use strict;
use warnings;
use autodie;
use v5.10;
use Test::More tests => 9;
use Test::Mojo;
use File::HomeDir::Test;
use File::HomeDir;
use YAML::XS qw( DumpFile );
use Mojo::URL;

$ENV{LOG_LEVEL} = "ERROR";

package SomeService;

$SomeService::VERSION = '1.1';

use base 'Clustericious::App';
use Clustericious::RouteBuilder;

get '/' => sub { shift->render_text('hello'); };

authenticate;
authorize;

get '/private' => sub { shift->render_text('this is private'); };

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
  
=pod

do {
  my $old_get = \&Mojo::UserAgent::get;
  my $new_get = sub {
    my($self, $url, @rest) = @_;
    $url = Mojo::URL->new($url);
    if($url->host eq 'simpleauth.test') {
      # TODO fake a various SimpleAuth responses
    } else {
      $old_get->(@_);
    }
  };
  no warnings 'redefine';
  *Mojo::UserAgent::get = $new_get;
};
  
$t->get_ok("http://foo:bar\@localhost:$port/private");
# ...

=cut

1;
