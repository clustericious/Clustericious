package Clustericious::Client::Object::Params;

use strict;
use warnings;
use base 'Clustericious::Client::Object';

# ABSTRACT: object parameters
our $VERSION = '0.9940_01'; # VERSION


sub new
{
    my $class = shift;
    my ($paramlist) = @_;

    $class->SUPER::new({ map { $_->{name} => $_->{value} } @$paramlist });
}

1;

__END__
=pod

=head1 NAME

Clustericious::Client::Object::Params - object parameters

=head1 VERSION

version 0.9940_01

=head1 SYNOPSIS

 my $data = 
 [
     { name => 'foo', value => 'foovalue' },
     { name => 'bar', value => 'barvalue' }
 ];

 my $obj = Clustericious::Client::Object::Params->new($data);

 $obj->{foo} -> 'foovalue';
 $obj->{bar} -> 'barvalue';

=head1 DESCRIPTION

Takes an array reference of hashes with 'name' and 'value' keys and
transforms it into a single flattened hash of name => value.

=head1 METHODS

=head2 C<new>

 my $obj = Clustericious::Client::Object::Params->new($data);

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

