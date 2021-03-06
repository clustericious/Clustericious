# Clustericious [![Build Status](https://secure.travis-ci.org/clustericious/Clustericious.png)](http://travis-ci.org/clustericious/Clustericious) [![Build status](https://ci.appveyor.com/api/projects/status/ifie1gwv9xyey7t6/branch/master?svg=true)](https://ci.appveyor.com/project/clustericious/Clustericious/branch/master)

(Deprecated) A framework for RESTful processing systems.

# SYNOPSIS

Generate a new Clustericious application:

    % clustericious generate app MyApp

Basic application layout:

    package MyApp;
    
    use Mojo::Base qw( Clustericious::App );
    
    sub startup
    {
      my($self) = @_;
      $self->SUPER::startup;
      # app startup
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

# DESCRIPTION

**NOTE**: This module has been deprecated, and may be removed on or after 31 December 2018.
Please see [https://github.com/clustericious/Clustericious/issues/46](https://github.com/clustericious/Clustericious/issues/46).

Clustericious is a web application framework designed to create HTTP/RESTful
web services that operate on a cluster, where each service does one thing 
and ideally does it well.  The design goal is to allow for easy deployment
of applications.  Clustericious is based on the [Mojolicious](https://metacpan.org/pod/Mojolicious) and borrows
some ideas from [Mojolicious::Lite](https://metacpan.org/pod/Mojolicious::Lite) ([Clustericious::RouteBuilder](https://metacpan.org/pod/Clustericious::RouteBuilder) is 
based on [Mojolicious::Lite](https://metacpan.org/pod/Mojolicious::Lite) routing).

Two examples of Clustericious applications on CPAN are [Yars](https://metacpan.org/pod/Yars) the archive
server and [PlugAuth](https://metacpan.org/pod/PlugAuth) the authentication server.

# FEATURES

Here are some of the distinctive aspects of Clustericious :

- Simplified route builder based on [Mojolicious::Lite](https://metacpan.org/pod/Mojolicious::Lite) (see [Clustericious::RouteBuilder](https://metacpan.org/pod/Clustericious::RouteBuilder)).
- Provides a set of default routes (e.g. /status, /version, /api) for consistent
interaction with Clustericious services (see [Clustericious::Plugin::CommonRoutes](https://metacpan.org/pod/Clustericious::Plugin::CommonRoutes)).
- Introspects the routes available and publishes the API as /api.
- Automatically handle different formats (YAML or JSON) depending on request 
(see [Clustericious::Plugin::AutodataHandler](https://metacpan.org/pod/Clustericious::Plugin::AutodataHandler)).
- Interfaces with [Clustericious::Client](https://metacpan.org/pod/Clustericious::Client) to allow easy creation of
clients.
- Uses [Clustericious::Config](https://metacpan.org/pod/Clustericious::Config) for configuration.
- Uses [Clustericious::Log](https://metacpan.org/pod/Clustericious::Log) for logging.
- Integrates with [Module::Build::Database](https://metacpan.org/pod/Module::Build::Database) and [Rose::Planter](https://metacpan.org/pod/Rose::Planter)
to provide a basic RESTful CRUD interface to a database.
- Provides 'stop' and 'start' commands, and high-level configuration
facilities for a variety of deployment options.

# AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis <plicease@cpan.org>

Contributors:

Curt Tilmes

Yanick Champoux

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
