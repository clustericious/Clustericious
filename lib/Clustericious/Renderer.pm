=head1 NAME

Clustericious::Renderer -- renderer for clustericious

=head1 DESCRIPTION

Just inherits from Mojolicious::Renderer with some customizations.

=head1 METHODS

=over

=cut

package Clustericious::Renderer;

use Clustericious::Log;
use base 'Mojolicious::Renderer';
use strict;
use warnings;

our $VERSION = '0.9918';

=item render

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

