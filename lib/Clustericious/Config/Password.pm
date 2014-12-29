package Clustericious::Config::Password;

use Data::Dumper;
use strict;
use warnings;

# ABSTRACT: Password routines for Clustericious::Config
our $VERSION = '0.9940_03'; # VERSION


our $Stashed;

sub sentinel {
    return "__XXX_placeholder_ceaa5b9c080d69ccdaef9f81bf792341__";
}

sub get {
    my $self = shift;
    require Term::Prompt;
    $Stashed ||= Term::Prompt::prompt('p', 'Password:', '', '');
    $Stashed;
}

sub is_sentinel {
    my $class = shift;
    my $val = shift;
    return (defined($val) && $val eq $class->sentinel);
}

1;


__END__
=pod

=head1 NAME

Clustericious::Config::Password - Password routines for Clustericious::Config

=head1 VERSION

version 0.9940_03

=head1 DESCRIPTION

This module provides the machinery for handling passwords used by
L<Clustericious::Config> and L<Clustericious::Config::Helpers>.

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

