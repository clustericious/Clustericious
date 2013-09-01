package Clustericious::Commands;

use strict;
use warnings;
use Clustericious::Config;
use Mojo::Base 'Mojolicious::Commands';

# ABSTRACT: Clustericious command runner
our $VERSION = '0.9930'; # VERSION


has namespaces => sub { [qw/Clustericious::Command Mojolicious::Command/] };

has app => sub { Mojo::Server->new->build_app('Clustericious::HelloWorld') };

sub start {
    my $self = shift;
    return $self->start_app($ENV{MOJO_APP} => @_) if $ENV{MOJO_APP};
    return $self->new->app->start(@_);
}

1;

__END__
=pod

=head1 NAME

Clustericious::Commands - Clustericious command runner

=head1 VERSION

version 0.9930

=head1 SYNOPSIS

 % yourapp start

=head1 DESCRIPTION

This class is used by the L<clustericious> command to do its thing.
See L<Clustericious::Command> for an overview of Clustericious commands.

=head1 SUPER CLASS

L<Mojolicious::Commands>

=head1 SEE ALSO

L<Clustericious::Command>

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

