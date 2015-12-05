package Clustericious::Command::generate::mbd_app;

use strict;
use warnings;
use Mojo::Base 'Clustericious::Command';
use File::Find;
use File::ShareDir 'dist_dir';
use File::Basename qw/basename/;

# ABSTRACT: Clustericious command to generate a new Clustericious M::B::D application
# VERSION

=head1 DESCRIPTION

This command has been removed.

=head1 SEE ALSO

L<Clustericious>

=cut


has description => <<'EOF';
Generate Clustericious app based on Module::Build::Database.
EOF

has usage => <<"EOF";
usage: $0 generate mbd_app [NAME]
EOF

sub run
{
  say STDERR "ERROR: this command has been removed";
  exit 2;
}

1;
