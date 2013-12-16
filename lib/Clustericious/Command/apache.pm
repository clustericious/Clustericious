package Clustericious::Command::apache;

use strict;
use warnings;
use Clustericious::App;
use Clustericious::Config;
use File::Path qw/mkpath/;
use base 'Clustericious::Command';
use Clustericious::Log;

# ABSTRACT: Clustericious command to stat Apache
our $VERSION = '0.9932'; # VERSION


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
    my $apache = qx[which httpd] or LOGDIE "could not find httpd in $ENV{PATH}";
    chomp $apache;
    DEBUG "starting $apache @args";
    system( $apache, @args ) == 0
      or die "could not start $apache @args ($?) "
      . ( ${^CHILD_ERROR_NATIVE} || '' );
}

1;


__END__
=pod

=head1 NAME

Clustericious::Command::apache - Clustericious command to stat Apache

=head1 VERSION

version 0.9932

=head1 SYNOPSIS

 % yourapp start

=head1 DESCRIPTION

Start an Apache web server.

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

