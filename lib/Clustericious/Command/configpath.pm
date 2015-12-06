package Clustericious::Command::configpath;

use strict;
use warnings;
use 5.010;
use Mojo::Base 'Clustericious::Command';
use Clustericious;

# ABSTRACT: Print the configuration path
# VERSION

=head1 SYNOPSIS

 % clustericious configpath

=head1 DESCRIPTION

Prints the Clustericious configuration path.

=head1 SEE ALSO

L<Clustericious>

=cut

has description => <<EOT;
Print configuration path.
EOT

has usage => <<EOT;
usage $0: configpath
EOT

sub run
{
  my($self, @args) = @_;
  say for Clustericious->_config_path  
}

1;

