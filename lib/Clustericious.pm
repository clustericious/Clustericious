package Clustericious;

=head1 NAME

Clustericious -- A framework for RESTful processing systems.

=head1 SYNPOSIS

    clustericious generate mbd_app Myapp --schema schema.sql

=head1 DESCRIPTION

Clustericious is a L<Mojo> based application framework, like (and inheriting
much from) L<Mojolicious> and L<Mojolicious::Lite>.  Its design goal is to
allow for easy development of applications which are part of an HTTP/RESTful
processing cluster.

=head1 FEATURES

Here are some of the distinctive aspects of Clustericious :

- Provides a set of default routes (e.g. /status, /version, /api) for consistent
interaction with L<Clustericious>-based processing nodes.

- Introspects the routes available and publishes the api as /api.

- Interfaces with L<Clustericious::Client> to allow easy creation of
clients.

- Uses L<Clustericious::Config> for configuration.

- Uses L<Clustericious::Log> for logging.

- Integrates with L<Module::Build::Database> and L<Rose::Planter>
to provide a basic RESTful CRUD interface to a database.

- Provides 'stop' and 'start' commands, and high-level configuration
facilities for a variety of deployment options.

=cut

our $VERSION = '0.9915';

=head1 TODO

Lots more documentation.

=head1 NOTES

This is a beta release.  The API is subject to change without notice.

=head1 SEE ALSO

L<Clustericious::App>,
L<Clustericious>,
L<Clustericious::RouteBuilder::CRUD>,
L<Clustericious::RouteBuilder::Search>,
L<Clustericious::RouteBuilder::Common>
L<Clustericious::Command::start>

=cut

1;

