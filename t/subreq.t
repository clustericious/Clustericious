use strict;
use warnings;
use v5.10;
use Test::Clustericious::Config;
use Test::Clustericious;
use Test::PlugAuth;
use Test::More tests => 12;

my $auth = Test::PlugAuth->new(auth => sub {
  my($user, $pass) = @_;
  return $user eq 'foo' && $pass eq 'bar';
});

create_config_ok MyApp => { 
  plug_auth => {
    url    => $auth->url,
    plugin => 'PlugAuth2',
  },
};

eval q{
  package MyApp;

  use base qw( Clustericious::App );
  our $VERSION = 0.01;

  package MyApp::Routes;
  
  use Clustericious::RouteBuilder;
  
  get '/' => sub { shift->render_text('hello') };
  
  get '/indirect' => sub {
    my($self) = @_;
    my $tx = $self->ua->transactor->tx( GET => '/private');
    $tx->{plug_auth_skip_auth} = 1;
    $self->app->handler($tx);
    my $res = $tx->success;
    $self->render( text => $res->body, status => $res->code );
  };
  
  authenticate;
  authorize;
  
  get '/private' => sub { shift->render_text('this is private') };
  
  package Clustericious::Plugin::PlugAuth2;
  
  use base qw( Clustericious::Plugin::PlugAuth );

  sub authenticate {
    return 1 if $_[1]->tx->{plug_auth_skip_auth};
    return shift->SUPER::authenticate(@_);
  };

  sub authorize {
    return 1 if $_[1]->tx->{plug_auth_skip_auth};
    return shift->SUPER::authenticate(@_);
  };

};
die $@ if $@;

my $t = Test::Clustericious->new('MyApp');
$auth->apply_to_client_app($t->app);

$t->get_ok('/')
  ->status_is(200);

$t->get_ok('/private')
  ->status_is(401);

my $port = eval { $t->ua->server->url->port } // $t->ua->app_url->port;

$t->get_ok("http://foo:bar\@localhost:$port/private")
  ->status_is(200);

$t->get_ok("http://foo1:ba1r\@localhost:$port/private")
  ->status_is(401);

$t->get_ok("/indirect")
  ->status_is(200)
  ->content_is('this is private');
