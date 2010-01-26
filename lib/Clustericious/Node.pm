package Clustericious::Node;

use base 'Mojolicious';
use MojoX::Log::Log4perl;

sub startup {
    my $self = shift;

    # Routes
    my $r = $self->routes;

    # Default route
    $self->log( MojoX::Log::Log4perl->new() );

    $self->log->trace("Initialized logger");

    Clustericious::RouteManager->add_routes($r);

}

1;

