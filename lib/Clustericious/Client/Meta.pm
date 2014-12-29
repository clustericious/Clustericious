package Clustericious::Client::Meta;

use strict;
use warnings;

# ABSTRACT: simple meta object for constructing clients
our $VERSION = '0.9940_03'; # VERSION

our %Routes; # hash from class name to array ref of routes.
our %RouteAttributes; # hash from class name to hash ref of attributes.
our %Objects; # hash from class name to array ref of objects.
our @CommonRoutes = ( [ "version" => '' ], [ "status" => '' ], [ "api" => '' ], [ "logtail" => '' ] );


sub add_route { # Keep track of routes that have are added.
    my $class      = shift;
    my $for        = shift;         # e.g. Restmd::Client
    my $route_name = shift;         # same as $subname
    my $route_doc  = shift || '';

    if (my ($found) = grep { $_->[0] eq $route_name } @{ $Routes{$for} }) {
        $found->[1] = $route_doc;
        return;
    }
    push @{ $Routes{$for} }, [ $route_name => $route_doc ];
}


sub get_route_doc {
    my $class      = shift;
    my $for        = shift;         # e.g. Restmd::Client
    my $route_name = shift;         # same as $subname
    my ($found) = grep { $_->[0] eq $route_name } @{ $Routes{$for} };
    return $found->[1];
}


sub add_route_attribute {
    my $class      = shift;
    my $for        = shift;         # e.g. Restmd::Client
    my $route_name = shift;
    my $attr_name  = shift;
    my $attr_value = shift;
    $RouteAttributes{$for}->{$route_name}{$attr_name} = $attr_value;
}


sub get_route_attribute {
    my $class      = shift;
    my $for        = shift;         # e.g. Restmd::Client
    my $route_name = shift;
    my $attr_name  = shift;
    return $RouteAttributes{$for}->{$route_name}{$attr_name};
}


sub add_object {
    my $class    = shift;
    my $for      = shift;
    my $obj_name = shift;
    my $obj_doc  = shift || '';
    push @{ $Objects{$for} }, [ $obj_name => $obj_doc ];
}


sub routes {
    my $class = shift;
    my $for = shift;
    return [ @CommonRoutes, @{$Routes{$for} || []}];
}

sub objects {
    my $class = shift;
    my $for = shift;
    return $Objects{$for};

}

1;




__END__
=pod

=head1 NAME

Clustericious::Client::Meta - simple meta object for constructing clients

=head1 VERSION

version 0.9940_03

=head1 METHODS

=head2 add_route

Add or replace documentation about a route.

Parameters :
    - the name of the client class
    - the name of the route
    - documentation about the route's arguments

=head2 get_route_doc

Get documentation for a route.

    $meta->get_route_doc($class,$route_name);

=head2 add_route_attribute

Add an attribute for a route.

Parameters :

    - the name of the attribute
    - the value of the attribute.

Recognized attributes :

    - dont_read_files : if set, no attempt will be made to treat
        arguments as yaml files.
    - auto_failover : if set, when a connection fails and does not
        return a status code, each url in the list of configured
        failover_url's will be tried in turn.

=head2 get_route_attribute

Like the above but retrieve an attribute.

=head2 add_object

Add an object>

Parameters :
    - the name of the client class
    - the name of the object
    - documentation about the object.

=head2 routes, objects

Return an array ref of routes/objects.

Each element is a two element array; the
first element is the name, the second is
documentation.

=head1 SEE ALSO

L<Clustericious::Client>, L<Clustericious>

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

