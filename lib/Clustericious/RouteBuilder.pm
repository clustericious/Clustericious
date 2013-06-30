package Clustericious::RouteBuilder;
use strict;
use warnings;

=head1 NAME

Clustericious::RouteBuilder - Route builder for Clustericious applications

=head1 SYNOPSIS

 use Clustericious::RouteBuilder;

=head1 DESCRIPTION

This class provides an interface for creating routes for Clustericious
applications, which was forked from L<Mojolicious::Lite> some time ago.

=head1 SUPER CLASS

none

=head1 SEE ALSO

L<Clustericious>, L<Mojolicious::Lite>

=cut

our $VERSION = '0.9927';

our %Routes;

# Much of the code below taken directly from Mojolicious::Lite.
sub import {
    my $class = shift;
    my $caller = caller;
    my $app_class;
    if (@_) { # allow specification in the "use".
        $app_class = shift;
    } elsif ($caller->isa("Clustericious::App")) {
        $app_class = $caller;
    } else {
        $app_class = $caller;
        $app_class =~ s/::Routes$// or die "could not guess app class : ";
    }
    my @routes;
    $Routes{$app_class} = \@routes;

    # Route generator
    my $route_sub = sub {
        my ($methods, @args) = @_;

        my ($cb, $constraints, $defaults, $name, $pattern);
        my $conditions = [];

        # Route information
        my $condition;
        while (my $arg = shift @args) {

            # Condition can be everything
            if ($condition) {
                push @$conditions, $condition => $arg;
                $condition = undef;
            }

            # First scalar is the pattern
            elsif (!ref $arg && !$pattern) { $pattern = $arg }

            # Scalar
            elsif (!ref $arg && @args) { $condition = $arg }

            # Last scalar is the route name
            elsif (!ref $arg) { $name = $arg }

            # Callback
            elsif (ref $arg eq 'CODE') { $cb = $arg }

            # Constraints
            elsif (ref $arg eq 'ARRAY') { $constraints = $arg }

            # Defaults
            elsif (ref $arg eq 'HASH') { $defaults = $arg }
        }

        # Defaults
        $cb ||= sub {1};
        $constraints ||= [];

        # Merge
        $defaults ||= {};
        $defaults = {%$defaults, cb => $cb};

        # Name
        $name ||= '';

        push @routes, {
            name        => $name,
            pattern     => $pattern,
            constraints => $constraints,
            conditions  => $conditions,
            defaults    => $defaults,
            methods     => $methods
          };

    };

    # Prepare exports
    no strict 'refs';
    no warnings 'redefine';

    # Export
    *{"${caller}::any"}          = sub { $route_sub->(ref $_[0] ? shift : [], @_) };
    *{"${caller}::get"}          = sub { $route_sub->('get', @_) };
    *{"${caller}::head"}         = sub { $route_sub->('head', @_) };
    *{"${caller}::ladder"}       = sub { $route_sub->('ladder', @_) };
    *{"${caller}::post"}         = sub { $route_sub->('post', @_) };
    *{"${caller}::put"}          = sub { $route_sub->('put', @_) };
    *{"${caller}::Delete"}       = sub { $route_sub->('delete', @_) };
    *{"${caller}::del"}          = sub { $route_sub->('delete', @_) };
    *{"${caller}::websocket"}    = sub { $route_sub->('websocket', @_) };
    *{"${caller}::authenticate"} = sub { $route_sub->('authenticate',@_) };
    *{"${caller}::authorize"}    = sub { $route_sub->('authorize',@_) };
}

sub add_routes {
    my $class = shift;
    my $app = shift;
    my $auth_plugin = shift;

    my $stashed = $Routes{ ref $app }
      or Carp::confess("no routes stashed for $app");
    my @stashed            = @$stashed;
    my $routes             = $app->routes;
    my $head_route         = $app->routes;
    my $head_authenticated = $head_route;

    for my $spec (@stashed) {
       my      ($name,$pattern,$constraints,$conditions,$defaults,$methods) =
       @$spec{qw/name  pattern  constraints  conditions  defaults  methods/};

         # authenticate, always connects to app->routes
         if (!ref $methods && $methods eq 'authenticate') {
             my $realm = $pattern || ref $app;
             my $cb = defined $auth_plugin ? sub { $auth_plugin->authenticate(shift, $realm) } : sub { 1 };
             $head_route = $head_authenticated = $routes =
             $app->routes->bridge->to( { cb => $cb } )->name("authenticated");
             next;
         }

         # authorize replaces previous authorize's
         if (!ref $methods && $methods eq 'authorize') {
            die "put authenticate before authorize" unless $head_authenticated;
            my $action = $pattern;
            my $resource = $name;
            if($auth_plugin)
            {
                $head_route = $routes = $head_authenticated->bridge->to( {
                        cb => sub {
                            my $c = shift;
                            # Dynamically compute resource/action
                            my ($d_resource,$d_action) = ($resource, $action);
                            $d_resource =~ s/<path>/$c->req->url->path/e if $d_resource;
                            $d_resource ||= $c->req->url->path;
                            $d_action =~ s/<method>/$c->req->method/e if $d_action;
                            $d_action ||= $c->req->method;
                            $auth_plugin->authorize( $c, $d_action, $d_resource );
                          } });
            }
            else
            {
                $head_route = $routes = $head_authenticated->bridge->to({ cb => sub { 1 } });
            }
            next;
         }

         # ladders don't replace previous ladders
         if (!ref $methods && $methods eq 'ladder') {
              die "constraints not handled in ladders" if $constraints && @$constraints;
              $routes = $routes->bridge( $pattern )->over($conditions)
                  ->to($defaults)->name($name);
              next;
         }

         # WebSocket?
         my $websocket = 1 if !ref $methods && $methods eq 'websocket';
         $methods = [] if $websocket;

         # Create route
         my $route =
           $routes->route( $pattern, @$constraints )->over($conditions)
           ->via($methods)->to($defaults)->name($name);

         # WebSocket
         $route->websocket if $websocket;
     }
}

1;

