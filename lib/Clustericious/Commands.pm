package Clustericious::Commands;

use strict;
use warnings;

=head1 NAME

Clustericious::Commands - Clustericious command runner

=head1 SYNOPSIS

 % yourapp start

=head1 DESCRIPTION

This class is used by the L<clustericious> command to do its thing.
See L<Clustericious::Command> for an overview of Clustericious commands.

=head1 SUPER CLASS

L<Mojolicious::Commands>

=head1 SEE ALSO

L<Clustericious::Command>

=cut

use Clustericious::Config;

use Mojo::Base 'Mojolicious::Commands';

our $VERSION = '0.9924';

has namespaces => sub { [qw/Clustericious::Command Mojolicious::Command/] };

has app => sub { Mojo::Server->new->build_app('Clustericious::HelloWorld') };

sub start {
    my $self = shift;
    return $self->start_app($ENV{MOJO_APP} => @_) if $ENV{MOJO_APP};
    return $self->new->app->start(@_);
}

1;
