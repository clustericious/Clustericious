package Clustericious::Renderer;

use strict;
use warnings;
use Clustericious::Log;
use base 'Mojolicious::Renderer';

# ABSTRACT: renderer for clustericious
our $VERSION = '0.9936'; # VERSION


sub render {
    my $self = shift;
    my ($c, $args) = @_;

    $c->stash->{handler} = "autodata" if exists($c->stash->{autodata}) || exists($args->{autodata});
    $self->SUPER::render(@_);
}

1;


__END__
=pod

=head1 NAME

Clustericious::Renderer - renderer for clustericious

=head1 VERSION

version 0.9936

=head1 DESCRIPTION

Just inherits from Mojolicious::Renderer with some customizations.

=head1 SUPER CLASS

L<Mojolicious::Renderer>

=head1 METHODS

=head2 render

Set the handler to "autodata" if there is some autodata
present in the stash.

=head1 SEE ALSO

L<Clustericious>

=head1 AUTHOR

original author: Brian Duggan

current maintainer: Graham Ollis <plicease@cpan.org>

contributors:

Curt Tilmes

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

