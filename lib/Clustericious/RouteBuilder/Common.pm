=head1 NAME

Clustericious::RouteBuilder::Common - Routes common to all clustericious apps.

=head1 SYNOPSIS

 Clustericious::RouteBuilder::Common->add_routes($app);

=head1 DESCRIPTION

This package adds routes that are common to all clustericious servers.

These routes will be added first; they cannot be overridden.  The following
routes are added :

    GET /version
    GET /status
    GET /api
    GET /log
    OPTIONS /

/log is not available unless the configuration option "export_logs" is set
to a true value.

=head1 SUPER CLASS

none

=head1 SEE ALSO

L<Clustericious>

=cut

package Clustericious::RouteBuilder::Common;
use Clustericious::Log;
use Sys::Hostname qw/hostname/;

our $VERSION = '0.9924_01';

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

    $app->routes->route('/api/:table')->to(
        cb => sub {
            my($self) = @_;
            my $table = $self->app->dump_api_table($self->stash('table'));
            $table ? $self->render( autodata => $table ) : $self->render_not_found;
        },
    );

    $app->routes->get('/log/:lines' => [ lines => qr/\d+/ ] =>
        sub {
            my $c = shift;
            my $lines = $c->stash("lines");
            unless ($c->config->export_logs(default => 0)) {
                return $c->render_text('logs not available');
            }
            $c->render_text(Clustericious::Log->tail(lines => $lines || 10) || '** empty log **');
        });

    $app->routes->options('/*opturl' => { opturl => '' } =>
        sub {
            my $c = shift;
            $c->res->headers->add( 'Access-Control-Allow-Methods' => 'GET, POST, OPTIONS' );
            # Allow-Origin and Allow-Headers added in after_dispatch hook.
            $c->render_text('ok');
        });
}

1;

