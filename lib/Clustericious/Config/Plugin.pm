package Clustericious::Config::Plugin;

use strict;
use warnings;
use Clustericious::Config::Helpers;

# ABSTRACT: Deprecated module
our $VERSION = '0.9940_03'; # VERSION


# Hack to keep old versions of Test::Clustericious::Cluster working
*EXPORT = \@Clustericious::Config::Helpers::EXPORT;

sub Clustericious::Config::Helpers::cluster
{
  goto &Clustericious::Config::Plugin::cluster;
}

1;

__END__
=pod

=head1 NAME

Clustericious::Config::Plugin - Deprecated module

=head1 VERSION

version 0.9940_03

=head1 DESCRIPTION

This is module is deprecated, please see
L<Clustericious::Config::Helper>.

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

