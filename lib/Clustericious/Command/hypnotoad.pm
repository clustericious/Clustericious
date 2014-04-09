package Clustericious::Command::hypnotoad;

use strict;
use warnings;
use Clustericious::Log;
use Clustericious::App;
use Clustericious::Config;
use Mojo::Server::Hypnotoad;
use Data::Dumper;
use File::Slurp qw/slurp/;
use Cwd qw/getcwd abs_path/;
use base 'Clustericious::Command';

# ABSTRACT: Clustericious command to stat Hypnotoad
our $VERSION = '0.9936'; # VERSION


__PACKAGE__->attr(description => "Start a hypnotad web server.\n");

__PACKAGE__->attr(usage => <<EOT);
Usage $0: hypnotoad
No options are available.  The 'hypnotoad' entry in the config file
is used for configuration.
EOT

sub run {
    my $self = shift;
    my $conf = Clustericious::Config->new($ENV{MOJO_APP})->hypnotoad;
    my %conf = %$conf;
    my $conf_string = Data::Dumper->Dump([\%conf],["conf"]);
    DEBUG "Config : $conf_string";
    my $exe = $0;
    DEBUG "Running hypnotoad : $exe";
    $ENV{HYPNOTOAD_EXE} = "$0 hypnotoad";
    my $sentinel = '/no/such/file/because/these/are/deprecated';
    if ( $ENV{HYPNOTOAD_CONFIG} && $ENV{HYPNOTOAD_CONFIG} ne $sentinel ) {
        WARN "HYPNOTOAD_CONFIG value $ENV{HYPNOTOAD_CONFIG} will be ignored";
    }
    # During deprecation, this value must be defined but not pass the -r test
    # to avoid warnings.
    my $pid = fork();
    if (!defined($pid)) {
        LOGDIE "Unable to fork";
    }

    unless ($pid) {
        DEBUG "Child process $$";
        local $ENV{HYPNOTOAD_CONFIG} = $sentinel;
        my $pid_file = $conf->{pid_file};
        if (-e $pid_file) {
            chomp (my $pid = slurp $pid_file);
            if (!kill 0, $pid) {
                WARN "removing old pid file $pid_file";
                unlink $pid_file or WARN "Could not remove $pid_file : $!";
            }
        }
        my $toad = Mojo::Server::Hypnotoad->new;
        $toad->run($exe);
        WARN "hypnotoad exited";
        exit;
    }
    sleep 1;
    return 1;
}

1;


__END__
=pod

=head1 NAME

Clustericious::Command::hypnotoad - Clustericious command to stat Hypnotoad

=head1 VERSION

version 0.9936

=head1 SYNOPSIS

in your application configuration (C<~/etc/YourApp.conf>)

 ---
 start_mode : "hypnotoad"
 hypnotoad:
    workers : 1
        listen :
            - "http://*:3000"
    inactivity_timeout : 50
    pid_file : /tmp/minionrelay.pid

then at the command line:

 % yourapp start

=head1 DESCRIPTION

Start a hypnotoad web server.

Configuration for the server is taken directly from the
"hypnotoad" entry in the config file, and turned into
a config file for hypnotoad.

=head1 SUPER CLASS

L<Clustericious::Command>

=head1 SEE ALSO

L<Clustericious>
L<Mojo::Server::Hypnotoad>,

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

