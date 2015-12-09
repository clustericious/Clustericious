package Clustericious::Plugin::ClustericiousHelpers;

use strict;
use warnings;
use 5.010001;
use Carp qw( carp );
use base qw( Mojolicious::Plugin );

sub register
{
  my ($self, $app, $conf) = @_;

  $app->helper(auth_ua => sub {
    my($c) = @_;
    carp "auth_ua has been deprecated";
    $c->ua;
  });

  $app->helper(render_moved => sub {
    my($c,@args) = @_;
    $c->res->code(301);
    my $where = $c->url_for(@args)->to_abs;
    $c->res->headers->location($where);
    $c->render(text => "moved to $where");
  });
}

1;
