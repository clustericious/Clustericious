package Clustericious::Command::lighttpd;

use strict;
use warnings;
use Clustericious::Log;
use Clustericious::App;
use Clustericious::Config;
use base 'Clustericious::Command';
use File::Which qw( which );

# ABSTRACT: Clustericious command to stat lighttpd
# VERSION

=head1 SYNOPSIS

 % yourapp start

=head1 DESCRIPTION

Start a lighttpd web server.
 
=head1 SEE ALSO

L<Clustericious>

=cut

__PACKAGE__->attr(description => <<EOT);
Start a lighttpd web server.
EOT

__PACKAGE__->attr(usage => <<EOT);
Usage $0: lighttpd -f <config file> [...other lighttpd options]
Starts a lighttpd webserver.
Options are passed verbatim to the lighttpd executable.
EOT

sub run {
    my $self = shift;
    my @args = @_ ? @_ : @ARGV;
    my $app_name = $ENV{MOJO_APP};

    # Clustericious::App->init_logging;

    my $lighttpd = which('lighttpd') or LOGDIE "could not find lighttpd in $ENV{PATH}";
    DEBUG "starting $lighttpd @args";
    system $lighttpd, @args;
    die "'$lighttpd @args' Failed to execute: $!" if $? == -1;
    die "'$lighttpd @args' Killed with signal: ", $? & 127 if $? & 127;
    die "'$lighttpd @args' Exited with ", $? >> 8 if $? >> 8;
}

1;


