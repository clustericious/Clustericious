=head1 NAME

Clustericious::Command::nginx

=head1 DESCRIPTION

Start an nginx web server.

=cut

package Clustericious::Command::nginx;
use Clustericious::App;
use Clustericious::Config;
use File::Path qw/mkpath/;
use base 'Mojo::Command';

use Clustericious::Log;
__PACKAGE__->attr(description => <<EOT);
Start an nginx web server.
EOT

__PACKAGE__->attr(usage => <<EOT);
Usage $0: nginx -p <prefix> [...other nginx options]
Starts an nginx webserver.
Options are passed verbatim to the nginx executable.
EOT

sub run {
    my $self = shift;
    my @args = @_ ? @_ : @ARGV;
    my $app_name = $ENV{MOJO_APP};
    my %args = @args;

    Clustericious::App->init_logging;

    my $prefix = $args{-p} or INFO "no prefix for nginx";
    mkpath "$prefix/logs";

    my $nginx = qx[which nginx] or LOGDIE "could not find nginx in $ENV{PATH}";
    chomp $nginx;
    DEBUG "starting $nginx @args";
    system( $nginx, @args ) == 0
      or die "could not start $nginx @args ($?) "
      . ( ${^CHILD_ERROR_NATIVE} || '' );
}

1;
