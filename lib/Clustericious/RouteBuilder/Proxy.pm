package Clustericious::RouteBuilder::Proxy;

use strict;
use warnings;
use Clustericious::Log;

# ABSTRACT: build proxy routes easily
our $VERSION = '0.9936'; # VERSION


use Sub::Exporter -setup => {
    exports => [
        "proxy" => \&_build_proxy,
        "proxy_service" => \&_build_proxy_service,
    ],
    collectors => ['defaults'],
};

sub _build_proxy {
    my ( $class, $name, $arg, $defaults ) = @_;
    my $strip_prefix  = $arg->{strip_prefix};
    my $destination   = $arg->{to};
    $destination = Clustericious::Config->new($arg->{app})->url if $arg->{app};
    die "Can't determine url for proxy route.\n" unless $destination;
    my $dest_url = Mojo::URL->new($destination);

    return sub {
        my $self = shift;

        my $url  = Mojo::URL->new( $self->req->url->to_string );
        $url->scheme( $dest_url->scheme );
        $url->host( $dest_url->host );
        $url->port( $dest_url->port );

        # NB: if there is a $base_url for this service, then any parts from
        # that should be stripped too.  So, this while() loop will remove
        # anything before the desired prefix.
        if ($strip_prefix) {
            $strip_prefix =~ s[^/][];
            my @parts = @{ $url->path->parts };
            my $last = '';
            while (my $got = shift @parts) {
                last if $got eq $strip_prefix;
            }
            $url->path->parts([@parts]);
        }
        if (@{ $dest_url->path->parts } && $dest_url->scheme) {
            unshift @{ $url->path->parts }, @{ $dest_url->path->parts };
        }

        LOGDIE "recursive proxy " if $self->req->url->to_abs eq $url->to_abs;

        my $remote = $self->tx->remote_address;
        TRACE "proxying (from $remote) " . $self->req->method . ' ' .
              _sanitize_url($self->req->url->to_abs) . " to " .
              _sanitize_url($url->to_abs);

        my $tx = Mojo::Transaction::HTTP->new;
        my $req = $tx->req;
        $req->method($self->req->method);
        $req->url($url);
        $req->body($self->req->body);
        my $headers = $self->req->headers->to_hash;
        delete $headers->{Host};
        $headers->{'X-Forwarded-For'} = $remote;
        $req->headers->from_hash($headers);
        $self->ua->inactivity_timeout($ENV{CLUSTERICIOUS_INACTIVITY_TIMEOUT} || 3000);
        $self->ua->max_redirects(10);
        $self->ua->start($tx);
        my $res = $self->tx->res;
        my $pr_res = $tx->res;
        $res->code($pr_res->code);
        $res->message($pr_res->message);
        $res->headers->content_type($pr_res->headers->content_type);
        $res->body($pr_res->body);
        $self->stash->{'rendered'} = 1;  # Cheat
        $self->rendered;
    }
}

sub _build_proxy_service {
    my ( $class, $name, $arg, $defaults ) = @_;
    my $name2url = $arg->{services}; # map name to url
    my $service2sub;
    for my $service (keys %$name2url) {
        my $dest = $name2url->{$service} or next;
        TRACE "Building proxy for $service to $dest";
        my $sub = $class->_build_proxy( "dummy", { to => $dest, strip_prefix => "/$service" } );
        $service2sub->{$service} = $sub;
    }
    return sub {
        my $c = shift;
        my $service = $c->stash("service") or die "no service in url";
        $service2sub->{$service}->($c);
    }
}

sub _sanitize_url {
    # Remove passwords from urls for displaying
    my $url = shift;
    $url = Mojo::URL->new($url) unless ref $url eq "Mojo::URL";
    return $url unless $url->userinfo;
    my $c = $url->clone;
    $c->userinfo("user:*****");
    return $c;
}

1;

__END__
=pod

=head1 NAME

Clustericious::RouteBuilder::Proxy - build proxy routes easily

=head1 VERSION

version 0.9936

=head1 SYNOPSIS

    use My::Object::Class;
    use Clustericious::RouteBuilder;
    use Clustericious::RouteBuilder::Proxy
      "proxy" => {
        to            => "http://google.com:80",
        strip_prefix  => "/google",
        -as           => "proxy_google",
      },
      "proxy" => {
        app => 'MyServer',
        -as => "proxy_local"
      },
      proxy_service => {  # Bulk mapping
             services => { "froogle" => "http://froogle.com",
                           "fraggle" => "http://fraggle.com" }
      };

    ...
    get '/google/:somewhere'    => \&proxy_google;
    get '/something/:somewhere' => \&proxy_local;
    get '/:service/(*whatever)' => \&proxy_service;

=head1 DESCRIPTION

This package provides routes for proxying.  It rewrites
URLs by stripping prefixes, and passes the rest on by
prepending a given url to the incoming request.

=head1 SUPER CLASS

none

=head1 SEE ALSO

L<Clustericious>

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

