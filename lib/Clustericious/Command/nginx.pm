package Clustericious::Command::nginx;

use strict;
use warnings;
use Clustericious::App;
use Clustericious::Config;
use File::Path qw/mkpath/;
use base 'Clustericious::Command';
use Clustericious::Log;

# ABSTRACT: Clustericious command to stat nginx
our $VERSION = '0.9941'; # VERSION


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


__END__
=pod

=head1 NAME

Clustericious::Command::nginx - Clustericious command to stat nginx

=head1 VERSION

version 0.9941

=head1 SYNOPSIS

 % yourapp start

=head1 DESCRIPTION

Start an nginx web server.

=head1 NAME

Clustericious::Command::nginx - Clustericious command to stat nginx

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

