package Clustericious::Command::lighttpd;

use strict;
use warnings;
use Clustericious::Log;
use Clustericious::App;
use Clustericious::Config;
use base 'Clustericious::Command';

# ABSTRACT: Clustericious command to stat lighttpd
our $VERSION = '0.9938'; # VERSION


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

    my $lighttpd = qx[which lighttpd] or LOGDIE "could not find lighttpd in $ENV{PATH}";
    chomp $lighttpd;
    DEBUG "starting $lighttpd @args";
    system( $lighttpd, @args ) == 0
      or die "could not start $lighttpd @args ($?) "
      . ( ${^CHILD_ERROR_NATIVE} || '' );
}

1;



__END__
=pod

=head1 NAME

Clustericious::Command::lighttpd - Clustericious command to stat lighttpd

=head1 VERSION

version 0.9938

=head1 SYNOPSIS

 % yourapp start

=head1 DESCRIPTION

Start a lighttpd web server.

=head1 SUPER CLASS

L<Clustericious::Command>

=head1 SEE ALSO

L<Clustericious>

=head1 AUTHOR

original author: Brian Duggan

current maintainer: Graham Ollis <plicease@cpan.org>

contributors:

Curt Tilmes

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

