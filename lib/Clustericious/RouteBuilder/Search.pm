=head1 NAME

Clustericious::RouteBuilder::Search -- build routes for searching for objects

=head1 SYNOPSIS

    use My::Object::Class;
    use Clustericious::RouteBuilder;
    use Clustericious::RouteBuilder::Search
            "search",
            "plurals",
            defaults => { manager_finder => "Manager::Finder::Class" },
        ;

    ...

    post => "/:plural/search" => [ plural => [ plurals() ] ] => \&do_create;

=head1 DESCRIPTION

This automates the creation of routes for searching for objects.

Manager::Finder::Class must the following methods :

 - lookup_class : given the plural of a table, look up the name of the class

=cut

package Clustericious::RouteBuilder::Search;
use Mojo::JSON;
use Log::Log4perl qw/:easy/;
use Data::Dumper;
use strict;

use Sub::Exporter -setup => {
    exports => [
        "search" => \&_build_search,
    ],
    collectors => ['defaults'],
};

sub _build_search {
    my ($class, $name, $arg, $defaults) = @_;
    my $finder = $arg->{finder} || $defaults->{defaults}{finder} || die "no finder defined";
    $finder->can("find_class") or die "$finder must be able to find_class";
    sub {
        my $self = shift;

        my $items = $self->stash("items") or LOGDIE "no items in request";

        my $manager = $finder->find_class($items) or LOGDIE "no class for $items";
        $self->app->plugins->run_hook('parse_data', $self);

        my $p = $self->stash->{data};

        TRACE "searching for $items : ".Dumper($p);

        # maybe restrict, by first calling $manager->normalize_get_objects_args(%$p)

        my $all = delete $p->{query_all};
        # "If the first argument is a hash it is treated as 'query'" -- RDBOM docs
        my @args = $all || exists( $p->{query} ) ? %$p
                 : ( keys %$p > 0 )              ? $p
                 : ();
        TRACE "args are @args";
        push @args, object_class => $manager->object_class;

        my $count = $manager->get_objects_count( @args );
        $self->stash->{data} = {
            count     => $count,
            resultset => [ map $_->as_hash, @{ $manager->get_objects( @args ) } ]
           };
    };
}

1;
