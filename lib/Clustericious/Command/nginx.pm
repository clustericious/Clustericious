=head1 NAME

Clustericious::Command::nginx - Clustericious command to stat nginx

=head1 SYNOPSIS

 % yourapp start

=head1 DESCRIPTION

Start an nginx web server.

=head1 SUPER CLASS

L<Clustericious::Command>

=head1 SEE ALSO

L<Clustericious>

=cut

package Clustericious::Command::nginx;
use Clustericious::App;
use Clustericious::Config;
use File::Path qw/mkpath/;
use base 'Clustericious::Command';

use Clustericious::Log;
__PACKAGE__->attr(description => <<EOT);
Start an nginx web server.
EOT

our $VERSION = '0.9922';

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

