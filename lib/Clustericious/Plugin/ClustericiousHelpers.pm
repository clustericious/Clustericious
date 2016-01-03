package Clustericious::Plugin::ClustericiousHelpers;

use strict;
use warnings;
use 5.010001;
use Carp qw( carp );
use base qw( Mojolicious::Plugin );
use Mojo::ByteStream qw( b );

# ABSTRACT: Helpers for Clustericious
# VERSION

=head1 DESCRIPTION

This class provides helpers for Clustericious.

=head1 HELPERS

In addition to the helpers provided by
L<Mojolicious::Plugin::DefaultHelpers> you get:

=cut

sub register
{
  my ($self, $app, $conf) = @_;

=head2 auth_ua

B<DEPRECATED>

Returns an instance of L<Mojo::UserAgent> that can be used
to authenticate against a L<PlugAuth> service.  Used primarily
for testing.

=cut

  $app->helper(auth_ua => sub {
    my($c) = @_;
    carp "auth_ua has been deprecated";
    $c->ua;
  });

=head2 base_tag

B<DEPRECATED>

=cut

  $app->helper(base_tag => sub {
    my $base = $app->config->url_base(default => '');
    carp "base_tag is deprecated";
    b("<base href='$base' />");
  });

=head2 render_moved

 $c->render_moved($path);

Render a 301 response.

=cut

  $app->helper(render_moved => sub {
    my($c,@args) = @_;
    $c->res->code(301);
    my $where = $c->url_for(@args)->to_abs;
    $c->res->headers->location($where);
    $c->render(text => "moved to $where");
  });

=head2 client

 my $client = $c->client;

Returns the appropriate L<Clustericious::Client> object for your app.

=cut

  do {
    my $client_class = ref($app) . "::Client";
    $client_class = 'Clustericious::Client'
      unless $client_class->can('new')
      ||     eval qq{ require $client_class; $client_class->can('new') };

    $app->helper(client => sub {
      $client_class->new(config => $app->config);
    });
  };

}

1;
