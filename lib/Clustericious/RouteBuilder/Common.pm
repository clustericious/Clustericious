=head1 NAME

Clustericious::RouteBuilder::Common -- routes common to all clustericious apps.

=head1 DESCRIPTION

This package adds routes that are common to all clustericious servers.

These routes will be added first; they cannot be overridden.

=cut

package Clustericious::RouteBuilder::Common;
use Log::Log4perl qw/:easy/;
use Clustericious::RouteBuilder;
our @ISA = qw/Clustericious::RouteBuilder/;

use strict;
use warnings;

get '/version' => sub {
    my $self = shift;
    $self->stash->{data} = [ $self->app->VERSION ];
}


