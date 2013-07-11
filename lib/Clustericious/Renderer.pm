=head1 NAME

Clustericious::Renderer - renderer for clustericious

=head1 DESCRIPTION

Just inherits from Mojolicious::Renderer with some customizations.

=head1 SUPER CLASS

L<Mojolicious::Renderer>

=head1 METHODS

=cut

package Clustericious::Renderer;

use Clustericious::Log;
use base 'Mojolicious::Renderer';
use strict;
use warnings;

our $VERSION = '0.9928';

=head2 render

Set the hander to "autodata" if there is some autodata
present in the stash.

=cut

sub render {
    my $self = shift;
    my ($c, $args) = @_;

    $c->stash->{handler} = "autodata" if exists($c->stash->{autodata}) || exists($args->{autodata});
    $self->SUPER::render(@_);
}

sub root  {
    my $self = shift;
    if (my $arg = shift) {
        $self->SUPER::paths([ $arg ]);
    }
    return $self;
}

1;

=head1 SEE ALSO

L<Clustericious>

=cut
