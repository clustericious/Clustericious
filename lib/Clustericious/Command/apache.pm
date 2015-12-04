package Clustericious::Command::apache;

use strict;
use warnings;
use Clustericious::App;
use Clustericious::Config;
use File::Path qw/mkpath/;
use base 'Clustericious::Command';
use Clustericious::Log;
use File::Which qw( which );

# ABSTRACT: Clustericious command to stat Apache
# VERSION

=head1 SYNOPSIS

 % yourapp start

=head1 DESCRIPTION

Start an Apache web server.

=head1 SUPER CLASS

L<Clustericious::Command>

=head1 SEE ALSO

L<Clustericious>

=cut

__PACKAGE__->attr(description => <<EOT);
Start an Apache web server.
EOT

__PACKAGE__->attr(usage => <<EOT);
Usage $0: Apache -f <conf> [...other Apache options]
Starts an Apache webserver.
Options are passed verbatim to the httpd executable.
EOT

sub run {
    my $self = shift;
    my @args = @_ ? @_ : @ARGV;
    my $app_name = $ENV{MOJO_APP};
    my %args = @args;

    Clustericious::App->init_logging;

    my $prefix = $args{-d} or INFO "no server root for Apache";
    mkpath "$prefix/logs" if $prefix;
    my $apache = which('httpd') or LOGDIE "could not find httpd in $ENV{PATH}";
    chomp $apache;
    DEBUG "starting $apache @args";
    system( $apache, @args ) == 0
      or die "could not start $apache @args ($?) "
      . ( ${^CHILD_ERROR_NATIVE} || '' );
}

1;

