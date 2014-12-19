package Clustericious::Config::Password;

use Data::Dumper;
use strict;
use warnings;

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

