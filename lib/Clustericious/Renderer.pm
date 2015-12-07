package Clustericious::Renderer;

use strict;
use warnings;
use Clustericious::Log;
use base 'Mojolicious::Renderer';

# ABSTRACT: renderer for clustericious
# VERSION

=head1 DESCRIPTION

Just inherits from Mojolicious::Renderer with some customizations.

=head1 SUPER CLASS

L<Mojolicious::Renderer>

=head1 METHODS

=head2 render

Set the handler to "autodata" if there is some autodata
present in the stash.

=cut

sub render
{
  my($self, $c, $args) = @_;
  $c->stash->{handler} = "autodata"
    if exists($c->stash->{autodata}) || exists($args->{autodata});
  $self->SUPER::render($c, $args);
}

1;

=head1 SEE ALSO

L<Clustericious>

=cut
