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
            defaults => { model => "My::Object::Class" },
        ;

    ...

    post => "/:table" => \&do_create;

=head1 DESCRIPTION

This package provides some handy subroutines for building CRUD
routes in your clustericious application.

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
    ],
    collectors => ['defaults'],
};

sub _build_create {
    my ($class, $name, $arg, $defaults) = @_;
    my $model = $arg->{model} || $defaults->{defaults}{model} || die "no model defined";
    $model->can("lookup_class") or die "$model must be able to lookup_class";
    return sub {
        my $self  = shift;
        $self->app->log->info("called do_create");
        my $table = $self->stash->{table};
        my $p = $self->req->headers->content_type eq "application/json"
              ? Mojo::JSON->new->decode( $self->req->body )
              : $self->req->params->to_hash;
        my $object_class = $model->lookup_class($table);
        my $object = $object_class->new(%$p);
        $object->save or $self->app->logdie( $object->errors );
        $self->stash->{json} = $object->as_tree;
    };
}

sub _build_read {
    my ($class, $name, $arg, $defaults) = @_;
    my $model = $arg->{model} || $defaults->{defaults}{model} || die "no model defined";
    $model->can("find_object") or die "$model must be able to find_object";
    sub {
        my $self  = shift;
        my $table = $self->stash->{table};
        my @keys = split /\//, $self->stash->{key};
        my $obj   = $model->find_object($table,@keys)
            or return $self->app->static->serve_404($self,"404.html.ep");
        $self->app->log->debug("Viewing $table @keys");

        $self->stash->{json} = $obj->as_tree;
    };
}

sub _build_delete {
    my ($class, $name, $arg, $defaults) = @_;
    my $model = $arg->{model} || $defaults->{defaults}{model} || die "no model defined";
    $model->can("find_object") or die "$model must be able to find_object";
    sub {
        my $self  = shift;
        my $table = $self->stash->{table};
        my @keys = split /\//, $self->stash->{key};
        my $obj   = $model->find_object($table,@keys)
            or return $self->app->static->serve_404($self,"404.html.ep");
        $self->app->log->debug("Deleting $table @keys");

        $obj->delete or $self->app->logdie($obj->errors);
        $self->stash->{text} = "ok";
    }
}

sub _build_update {
    return sub { die "update not yet implemented"; };
}


1;

