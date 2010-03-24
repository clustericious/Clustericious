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

The objects returned by find_object must be have a method
named as_hash.

=head1 TODO

more documentation

=cut

use Mojo::JSON;
use strict;

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
        my $p = $self->req->headers->content_type eq "application/json"
              ? Mojo::JSON->new->decode( $self->req->body )
              : $self->req->params->to_hash;
        my $object_class = $finder->find_class($table);
        my $object = $object_class->new(%$p);
        $object->save or $self->app->logdie( $object->errors );
        $self->stash->{json} = $object->as_hash;
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
        my $obj   = $finder->find_object($table,@keys)
            or return $self->app->static->serve_404($self,"404.html.ep");
        $self->app->log->debug("Viewing $table @keys");

        $self->stash->{json} = $obj->as_hash;

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
        my $obj   = $finder->find_object($table,@keys)
            or return $self->app->static->serve_404($self,"404.html.ep");
        $self->app->log->debug("Deleting $table @keys");

        $obj->delete or $self->app->logdie($obj->errors);
        $self->stash->{text} = "ok";
    }
}

sub _build_update {
    return sub { die "update not yet implemented"; };
}

sub _build_list {
    my ($class, $name, $arg, $defaults) = @_;
    my $finder = $arg->{finder} || $defaults->{defaults}{finder} || die "no finder defined";
    $finder->can("find_object") or die "$finder must be able to find_object";
    sub {
        my $self  = shift;
        my $table = $self->stash->{table};

        $self->app->log->debug("Listing $table");

        my $object_class = Rose::Planter->find_class($table)
            or return $self->app->static->serve_404($self, "404.html.ep");

        my $pkey = $object_class->meta->primary_key;

        my $manager = $object_class . '::Manager';

        my $objectlist = $manager->get_objects(object_class => $object_class,
                                               sort_by => $pkey);

        $self->stash->{json} = [ map { $_->$pkey } @$objectlist ];
    };
}

1;
