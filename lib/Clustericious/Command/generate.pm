package Clustericious::Command::generate;

use strict;
use warnings;
use Mojo::Base 'Mojolicious::Command::generate';

# ABSTRACT: Clustericious code generation commands.
# VERSION

=head1 SYNOPSIS

 % clustericious generate app MyApp
 % clustericious generate client MyApp

=head1 DESCRIPTION

This is the base class for all Clustericious code generation commands.
It inherits from L<Mojolicious::Command::generate> instead of
L<Clustericious::Command>.

=head1 SEE ALSO

L<Clustericious>

=cut

has namespaces =>
      sub { [qw/Clustericious::Command::generate
                Mojolicious::Command::generate
                Mojo::Command::generate/] };

1;
