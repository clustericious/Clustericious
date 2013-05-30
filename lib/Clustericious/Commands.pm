package Clustericious::Commands;

use strict;
use warnings;

use Clustericious::Config;

use Mojo::Base 'Mojolicious::Commands';

our $VERSION = '0.9921';

has namespaces => sub { [qw/Clustericious::Command Mojolicious::Command/] };

has app => sub { Mojo::Server->new->build_app('Clustericious::HelloWorld') };

sub start {
    my $self = shift;
    return $self->start_app($ENV{MOJO_APP} => @_) if $ENV{MOJO_APP};
    return $self->new->app->start(@_);
}

1;
