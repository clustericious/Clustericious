package Clustericious::RouteBuilder;
use strict;
use warnings;

our @Routes;

# Much of the code below taken directly from Mojolicious::Lite.
sub import {
    my $class = shift;

    # Route generator
    my $route_sub = sub {
        my ($methods, @args) = @_;
        our @Routes;

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
        $defaults = {%$defaults, callback => $cb};

        # Name
        $name ||= '';

        push @Routes, {
            name        => $name,
            pattern     => $pattern,
            constraints => $constraints,
            conditions  => $conditions,
            defaults    => $defaults,
            methods     => $methods
          };

    };

    # Prepare exports
    my $caller = caller;
    no strict 'refs';
    no warnings 'redefine';

    # Export
    *{"${caller}::any"}       = sub { $route_sub->(ref $_[0] ? shift : [], @_) };
    *{"${caller}::get"}       = sub { $route_sub->('get', @_) };
    *{"${caller}::ladder"}    = sub { $route_sub->('ladder', @_) };
    *{"${caller}::post"}      = sub { $route_sub->('post', @_) };
    *{"${caller}::Delete"}    = sub { $route_sub->('delete', @_) };
    *{"${caller}::websocket"} = sub { $route_sub->('websocket', @_) };
}

sub add_routes {
    my $class = shift;
    my $app = shift;

    my $routes = $app->routes;

    for my $spec (@Routes) {
       my      ($name,$pattern,$constraints,$conditions,$defaults,$methods) =
       @$spec{qw/name  pattern  constraints  conditions  defaults  methods/};

        do {
          $routes = $app->routes->bridge( $pattern, {@$constraints} )->over($conditions)
              ->to($defaults)->name($name);
          next;
         } if !ref $methods && $methods eq 'ladder';

         # WebSocket?
         my $websocket = 1 if !ref $methods && $methods eq 'websocket';
         $methods = [] if $websocket;

         # Create route
         my $route =
           $routes->route( $pattern, {@$constraints} )->over($conditions)
           ->via($methods)->to($defaults)->name($name);

         # WebSocket
         $route->websocket if $websocket;
     }
}

1;

