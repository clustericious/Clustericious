package Clustericious::HelloWorld;

use strict;
use warnings;
use Mojo::Base 'Clustericious::App';
use Clustericious::RouteBuilder qw/Clustericious::HelloWorld/;

# ABSTRACT: Clustericious hello world application
our $VERSION = '0.9941'; # VERSION


BEGIN {
    $ENV{LOG_LEVEL} = 'FATAL';
}

any '/*foo' => {foo => '', text => 'Clustericious is working!'};

1;

__END__
=pod

=head1 NAME

Clustericious::HelloWorld - Clustericious hello world application

=head1 VERSION

version 0.9941

=head1 SYNOPSIS

 % MOJO_APP=Clustericious::HelloWorld clustericious start

=head1 DESCRIPTION

A very simple example Clustericious application intended for testing only.

=head1 SUPER CLASS

L<Clustericious::App>

=head1 SEE ALSO

L<Clustericious>, L<Mojo::HelloWorld>

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

