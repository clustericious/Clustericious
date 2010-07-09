=head1 NAME

Clustericious::Command::Plackup

=head1 DESCRIPTION

Start a plack server using plackup.

=head1 SEE ALSO

plackup, Plack

=cut

package Clustericious::Command::Plackup;
use Log::Log4perl qw/:easy/;

use Clustericious::App;
use Mojo::Server::PSGI;
use base 'Mojo::Command';

use strict;
use warnings;

__PACKAGE__->attr(description => <<EOT);
Start a plack server (see plackup)
EOT

__PACKAGE__->attr(usage => <<EOT);
Usage $0: plackup [plackup options]
Starts a plack server.  See plackup for valid options.
EOT

sub run {
    my $self = shift;
    my @args = @_ ? @_ : @ARGV;
    my $app_name = $ENV{MOJO_APP};
    my $conf = Clustericious::Config->new( $app_name );

    Clustericious::App->init_logging;

    my $plackup = qx[which plackup] or LOGDIE "could not find plackup in $ENV{PATH}";
    chomp $plackup;

    DEBUG "starting $plackup @args";
    system($plackup, @args)==0 or die "could not start $plackup @args";
}

1;

