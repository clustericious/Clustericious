package Clustericious::Command::plackup;

use strict;
use warnings;
use Clustericious::Log;
use Clustericious::App;
use Mojo::Server::PSGI;
use base 'Clustericious::Command';

# ABSTRACT: Clustericious command to start plack server
our $VERSION = '0.9940_03'; # VERSION


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
    delete $ENV{MOJO_COMMANDS_DONE};
    system( $plackup, @args ) == 0
      or die "could not start $plackup @args ($?) "
      . ( ${^CHILD_ERROR_NATIVE} || '' );
}

1;


__END__
=pod

=head1 NAME

Clustericious::Command::plackup - Clustericious command to start plack server

=head1 VERSION

version 0.9940_03

=head1 SYNOPSIS

 % yourapp start

=head1 DESCRIPTION

Start a plack server using plackup.

=head1 SUPER CLASS

L<Clustericious::Command>

=head1 SEE ALSO

L<Clustericious>, L<plackup>, L<Plack>

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

