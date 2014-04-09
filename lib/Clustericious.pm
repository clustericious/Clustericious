package Clustericious;

use strict;
use warnings;

# ABSTRACT: A framework for RESTful processing systems.
our $VERSION = '0.9936'; # VERSION


1;


__END__
=pod

=head1 NAME

Clustericious - A framework for RESTful processing systems.

=head1 VERSION

version 0.9936

=head1 SYNOPSIS

Generate a new Clustericious application:

 % clustericious generate app MyApp

Generate a new Clustericious application database schema:

 % clustericious generate mbd_app MyApp --schema schema.sql

Basic application layout:

 package MyApp;
 
 use Mojo::Base qw( Clustericious::App );
 
 sub startup
 {
   my($self) = @_;
   # just like Mojolicious startup()
 }
 
 package MyApp::Routes;
 
 use Clustericious::RouteBuilder;
 
 # Mojolicious::Lite style routing
 get '/' => sub { shift->render(text => 'welcome to myapp') };

Basic testing for Clustericious application:

 use Test::Clustericious::Cluster;
 use Test::More tests => 4;
 
 # see Test::Clustericious::Cluster for more details
 # and examples.
 my $cluster = Test::Clustericious::Cluster->new;
 $cluster->create_cluster_ok('MyApp');    # 1
 
 my $url = $cluster->url;
 my $t   = $cluster->t;   # Test::Mojo object
 
 $t->get_ok("$url/")                      # 2
   ->status_is(200)                       # 3
   ->content_is('welcome to myapp');      # 4
 
 __DATA__
 
 @ etc/MyApp.conf
 ---
 url: <%= cluster->url %>

=head1 DESCRIPTION

Clustericious is a web application framework designed to create HTTP/RESTful
web services that operate on a cluster, where each service does one thing 
and ideally does it well.  The design goal is to allow for easy deployment
of applications.  Clustericious is based on the L<Mojolicious> and borrows
some ideas from L<Mojolicious::Lite> (L<Clustericious::RouteBuilder> is 
based on L<Mojolicious::Lite> routing).

Two examples of Clustericious applications on CPAN are L<Yars> the archive
server and L<PlugAuth> the authentication server.

=head1 FEATURES

Here are some of the distinctive aspects of Clustericious :

=over 4

=item *

Simplified route builder based on L<Mojolicious::Lite> (see L<Clustericious::RouteBuilder>).

=item *

Provides a set of default routes (e.g. /status, /version, /api) for consistent
interaction with Clustericious services (see L<Clustericious::RouteBuilder::Common>).

=item *

Introspects the routes available and publishes the API as /api.

=item *

Automatically handle different formats (YAML or JSON) depending on request 
(see L<Clustericious::Plugin::AutodataHandler>).

=item *

Interfaces with L<Clustericious::Client> to allow easy creation of
clients.

=item *

Uses L<Clustericious::Config> for configuration.

=item *

Uses L<Clustericious::Log> for logging.

=item *

Integrates with L<Module::Build::Database> and L<Rose::Planter>
to provide a basic RESTful CRUD interface to a database.

=item *

Provides 'stop' and 'start' commands, and high-level configuration
facilities for a variety of deployment options.

=back

=head1 TODO

I am ramping up to a release candidate and a final release for 1.00.
Specific things that need to be completed for this task include
(but are not limited to):

=over 4

=item *

documentation tutorial for a non database app

=item *

documentation tutorial for a L<Module::Build::Database> / L<Rose::Planter> app 
(replacement for the existing README, which is broken)

=item *

use SQLite for above instead of Postgres

=item *

documentation tutorial for migrating SQLite app to Postgres

=item *

documentation tutorial for clients (L<Clustericious::Client>)

=item *

remove C<TEST_HARNESS> detection / dependency (see GH#8)

=back

=head1 NOTES

This is a beta release.  The API is subject to change without notice.

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

