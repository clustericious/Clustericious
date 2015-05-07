package Clustericious::Util;

use strict;
use warnings;
use base qw( Exporter );

our @EXPORT_OK = qw( slurp_pid );

# ABSTRACT: Utility functions used by Clustericious
our $VERSION = '1.00'; # VERSION


sub slurp_pid ($)
{
  use autodie;
  my($fn) = @_;
  open my $fh, '<', $fn;
  my $pid = <$fh>;
  close $fh;
  chomp $pid;
  $pid;
}

1;

__END__
=pod

=head1 NAME

Clustericious::Util - Utility functions used by Clustericious

=head1 VERSION

version 1.00

=head1 DESCRIPTION

Used internally by Clustericious only.

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

