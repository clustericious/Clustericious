package Clustericious::Util;

use strict;
use warnings;
use base qw( Exporter );

our @EXPORT_OK = qw( slurp_pid );

# ABSTRACT: Utility functions used by Clustericious
# VERSION

=head1 DESCRIPTION

Used internally by Clustericious only.

=cut

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
