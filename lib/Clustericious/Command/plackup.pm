package Clustericious::Command::plackup;

use strict;
use warnings;
use Clustericious::Log;
use Clustericious::App;
use Mojo::Server::PSGI;
use base 'Clustericious::Command';
use File::Which qw( which );

# ABSTRACT: Clustericious command to start plack server
# VERSION

=head1 SYNOPSIS

 % yourapp start

=head1 DESCRIPTION

Start a plack server using plackup.

=head1 SUPER CLASS

L<Clustericious::Command>

=head1 SEE ALSO

L<Clustericious>, L<plackup>, L<Plack>

=cut

__PACKAGE__->attr(description => <<EOT);
Start a plack server (see plackup)
EOT

__PACKAGE__->attr(usage => <<EOT);
Usage $0: plackup [plackup options]
Starts a plack server.  See plackup for valid options.
EOT

sub run {
    my $self = shift;
    my $app_name = $ENV{MOJO_APP};
    my $conf = Clustericious::Config->new( $app_name );

    Clustericious::App->init_logging;

    my $plackup = which('plackup') || LOGDIE "could not find plackup in $ENV{PATH}";

    DEBUG "starting $plackup $0";
    delete $ENV{MOJO_COMMANDS_DONE};
    system( $plackup, $0 ) == 0
      or die "could not start $plackup $0 ($?) "
      . ( ${^CHILD_ERROR_NATIVE} || '' );
}

1;

