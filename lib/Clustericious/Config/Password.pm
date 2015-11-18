package Clustericious::Config::Password;

use strict;
use warnings;
use 5.010;

# ABSTRACT: Password routines for Clustericious::Config
# VERSION

=head1 DESCRIPTION

This module provides the machinery for handling passwords used by
L<Clustericious::Config> and L<Clustericious::Config::Helpers>.

=head1 AUTHORS

Brian Duggan

Graham Ollis <gollis@sesda3.com>

=head1 SEE ALSO

L<Clustericious::Config>, L<Clustericious>

=cut

sub sentinel {
    return "__XXX_placeholder_ceaa5b9c080d69ccdaef9f81bf792341__";
}

sub get {
    my $self = shift;
    state $pass;
    $pass //= do { require Term::Prompt; Term::Prompt::prompt('p', 'Password:', '', '') };
    $pass;
}

sub is_sentinel {
    my $class = shift;
    my $val = shift;
    return (defined($val) && $val eq $class->sentinel);
}

1;

