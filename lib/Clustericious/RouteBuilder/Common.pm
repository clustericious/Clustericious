=head1 NAME

Clustericious::RouteBuilder::Common -- routes common to all clustericious apps.

=head1 DESCRIPTION

This package adds routes that are common to all clustericious servers.

These routes will be added first; they cannot be overridden.

=cut

package Clustericious::RouteBuilder::Common;
use Log::Log4perl qw/:easy/;
use Sys::Hostname qw/hostname/;

use strict;
use warnings;

sub add_routes {
    my $class = shift;
    my $app = shift;

    $app->routes->route('/version')->to(
        cb => sub {
            my $self = shift;
            $self->stash(autodata => [ $self->app->VERSION ]);
        }
    );

    $app->routes->route('/status')->to(
        cb => sub {
            my $self = shift;
            my $app = ref $self->app || $self->app;
            $self->stash(autodata => { app_name => $app,
                                     server_version => $self->app->VERSION,
                                     server_hostname => hostname(),
                                     server_url => $self->config->url(default => 'undef') });
        }
    );

    $app->routes->route('/api')->to(
        cb => sub {
            my $self = shift;
            $self->render( autodata => [ $self->app->dump_api() ] );
            }
    );
}

1;

