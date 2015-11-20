package Clustericious::RouteBuilder::Common;

use strict;
use warnings;
use Clustericious::Log;
use Sys::Hostname qw/hostname/;

# ABSTRACT: Routes common to all clustericious applications
# VERSION

=head1 DESCRIPTION

This package adds routes that are common to all clustericious servers.

=head1 SUPER CLASS

none

=cut

sub _add_routes {
    my $class = shift;
    my $app = shift;

=head2 /version

Returns the version of the service as a single element list.

=cut

    $app->routes->route('/version')->to(
        cb => sub {
            my $self = shift;
            $self->stash(autodata => [ $self->app->VERSION ]);
        }
    );

=head2 /status

Returns status information about the service.  This comes back
as a hash that includes these key/value pairs:

=over 4

=item app_name

The name of the application (example: "MyApp")

=item server_hostname

The server on which the service is running.

=item server_url

The URL to use for the service.

=item server_version

The version of the application.

=back

=cut

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

=head2 /api

Returns a list of API routes for the service.  This is similar to the information
provided by the L<Mojolicious::Command::routes|routes command>.

=cut

    $app->routes->route('/api')->to(
        cb => sub {
            my $self = shift;
            $self->render( autodata => [ $self->app->dump_api() ] );
            }
    );

=head2 /api/:table

If you are using L<Module::Build::Database> and L<Route::Planter> for a database
back end to your L<Clustericious> application you can get the columns of each
table using this route.

=cut

    $app->routes->route('/api/:table')->to(
        cb => sub {
            my($self) = @_;
            my $table = $self->app->dump_api_table($self->stash('table'));
            $table ? $self->render( autodata => $table ) : $self->reply->not_found;
        },
    );
    
=head2 /log/:lines

Return the last several lines from the application log (number specified by :lines
and defaults to 10 if not specified).

Only available if you set export_logs to true in your application's server configuration.

example C<~/etc/MyApp.conf>:

 ---
 export_logs: 1

=cut

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

=head1 SEE ALSO

L<Clustericious>, L<Clustericious::RouteBuilder>

=cut
