=head1 NAME

Clustericious::Command::apache - Clustericious command to stat Apache

=head1 SYNOPSIS

 % yourapp start

=head1 DESCRIPTION

Start an apache web server.

=head1 SUPER CLASS

L<Clustericious::Command>

=head1 SEE ALSO

L<Clustericious>

=cut

package Clustericious::Command::apache;
use Clustericious::App;
use Clustericious::Config;
use File::Path qw/mkpath/;
use base 'Clustericious::Command';

use Clustericious::Log;
__PACKAGE__->attr(description => <<EOT);
Start an apache web server.
EOT

our $VERSION = '0.9924';

__PACKAGE__->attr(usage => <<EOT);
Usage $0: apache -f <conf> [...other apache options]
Starts an apache webserver.
Options are passed verbatim to the httpd executable.
EOT

sub run {
    my $self = shift;
    my @args = @_ ? @_ : @ARGV;
    my $app_name = $ENV{MOJO_APP};
    my %args = @args;

    Clustericious::App->init_logging;

    my $prefix = $args{-d} or INFO "no server root for apache";
    mkpath "$prefix/logs" if $prefix;
    my $apache = qx[which httpd] or LOGDIE "could not find httpd in $ENV{PATH}";
    chomp $apache;
    DEBUG "starting $apache @args";
    system( $apache, @args ) == 0
      or die "could not start $apache @args ($?) "
      . ( ${^CHILD_ERROR_NATIVE} || '' );
}

1;

