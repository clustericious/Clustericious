package Clustericious::RouteBuilder::CRUD;

=head1 NAME

Clustericious::RouteBuilder::CRUD -- build crud routes easily

=head1 SYNOPSIS

    use My::Object::Class;
    use Clustericious::RouteBuilder;
    use Clustericious::RouteBuilder::CRUD
            "create" => { -as => "do_create" },
            "read"   => { -as => "do_read"   },
            "delete" => { -as => "do_delete" },
            "update" => { -as => "do_update" },
            "list"   => { -as => "do_list"   },
            defaults => { finder => "My::Finder::Class" },
        ;

    ...

    post => "/:table" => \&do_create;

=head1 DESCRIPTION

This package provides some handy subroutines for building CRUD
routes in your clustericious application.

The class referenced by "finder" must have methods named
find_class and find_object.

The objects returned by find_object must have a method named as_hash.

=head1 TODO

more documentation

=cut

use strict;
use Log::Log4perl qw/:easy/;
use List::MoreUtils qw(any);

use Sub::Exporter -setup => {
    exports => [
        "create" => \&_build_create,
        "read"   => \&_build_read,
        "update" => \&_build_update,
        "delete" => \&_build_delete,
        "list"   => \&_build_list,
    ],
    collectors => ['defaults'],
};

sub _build_create {
    my ($class, $name, $arg, $defaults) = @_;
    my $finder = $arg->{finder} || $defaults->{defaults}{finder} || die "no finder defined";
    $finder->can("find_class") or die "$finder must be able to find_class";
    return sub {
        my $self  = shift;
        $self->app->log->info("called do_create");
        my $table = $self->stash->{table};
        TRACE "create $table";
        $self->app->plugins->run_hook('parse_data', $self);
        my $object_class = $finder->find_class($table);
        my $object = $object_class->new(%{$self->stash->{data}});
        $object->save or $self->app->logdie( $object->errors );
        $self->stash->{data} = $object->as_hash;
    };
}

sub _build_read {
    my ($class, $name, $arg, $defaults) = @_;
    my $finder = $arg->{finder} || $defaults->{defaults}{finder} || die "no finder defined";
    $finder->can("find_object") or die "$finder must be able to find_object";
    sub {
        my $self  = shift;
        my $table = $self->stash->{table};
        my @keys = split /\//, $self->stash->{key};
        TRACE "read $table (@keys)";
        my $obj   = $finder->find_object($table,@keys)
            or return $self->app->static->serve_404($self,"404.html.ep");
        $self->app->log->debug("Viewing $table @keys");

        $self->stash->{data} = $obj->as_hash;

    };
}

sub _build_delete {
    my ($class, $name, $arg, $defaults) = @_;
    my $finder = $arg->{finder} || $defaults->{defaults}{finder} || die "no finder defined";
    $finder->can("find_object") or die "$finder must be able to find_object";
    sub {
        my $self  = shift;
        my $table = $self->stash->{table};
        my @keys = split /\//, $self->stash->{key};
        TRACE "delete $table (@keys)";
        my $obj   = $finder->find_object($table,@keys)
            or return $self->app->static->serve_404($self,"404.html.ep");
        $self->app->log->debug("Deleting $table @keys");

        $obj->delete or $self->app->logdie($obj->errors);
        $self->stash->{text} = "ok";
    }
}

sub _build_update {
    my ($class, $name, $arg, $defaults) = @_;

    my $finder = $arg->{finder} || $defaults->{defaults}{finder}
                 || die "no finder defined";

    $finder->can("find_object") or die "$finder must be able to find_object";

    sub {
        my $self  = shift;
        my $table = $self->stash->{table};
        my @keys = split /\//, $self->stash->{key};

        my $obj = $finder->find_object($table, @keys)
            or return $self->app->static->serve_404($self, "404.html.ep");

        $self->app->log->debug("Updating $table @keys");

        my $pkeys = $obj->meta->primary_key_column_names;
        my $ukeys = $obj->meta->unique_keys_column_names;
        my $columns = $obj->meta->column_names;
        my $nested = $finder->nested_tables($table);

        while (my ($key, $value) = each %{$self->stash->{data}})
        {
            next if any { $key eq $_ } @$pkeys, @$ukeys; # Skip key fields

            $self->app->logdie("Can't update $key")
                unless any { $key eq $_ } @$columns, @$nested;

            $obj->$key($value) or $self->app->logdie($obj->errors);
        }

        $obj->save or $self->app->logdie($obj->errors);

        $self->stash->{data} = $obj->as_hash;
    };
}

sub _build_list {
    my ($class, $name, $arg, $defaults) = @_;
    my $finder = $arg->{finder} || $defaults->{defaults}{finder} || die "no finder defined";
    $finder->can("find_object") or die "$finder must be able to find_object";
    sub {
        my $self  = shift;
        my $table = $self->stash('table');
        my $params = $self->stash('params');
        my $limit = $params ? $params->param('limit') : 10;

        $self->app->log->debug("Listing $table");

        my $object_class = $finder->find_class($table)
            or return $self->app->static->serve_404($self, "404.html.ep");

        my $pkey = $object_class->meta->primary_key;

        my $manager = $object_class . '::Manager';

        my $objectlist = $manager->get_objects(
                             object_class => $object_class,
                             select => [ $pkey->columns ],
                             sort_by => [ $pkey->columns ],
                             limit => $limit);

        my @l;

        foreach my $obj (@$objectlist) {
            push(@l, join('/', map { $obj->$_ } $pkey->columns ));
        }

        $self->stash->{data} = \@l;
    };
}

1;
