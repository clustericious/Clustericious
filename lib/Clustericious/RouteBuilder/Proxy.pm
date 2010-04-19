package Clustericious::RouteBuilder::Proxy;

=head1 NAME

Clustericious::RouteBuilder::Proxy -- build proxy routes easily

=head1 SYNOPSIS

    use My::Object::Class;
    use Clustericious::RouteBuilder;
    use Clustericious::RouteBuilder::Proxy
      "proxy" => {
        to            => "http://google.com:80",
        strip_prefix  => "/google"
        -as           => "proxy_google",
      },
      "proxy" => {
        to => "http://localhost:1023",
        -as => "proxy_local"
      },
      ;

    ...
    get => "/google/:somewhere"    => \&proxy_google;
    get => "/something/:somewhere" => \&proxy_local;

=head1 DESCRIPTION

This package provides routes for proxying.  It rewrites
urls by stripping prefixes, and passes the rest on by
prepending a given url to the incoming request.

=head1 TODO

more documentation

=cut

use Log::Log4perl qw/:easy/;
use strict;

use Sub::Exporter -setup => {
    exports => [
        "proxy" => \&_build_proxy,
    ],
    collectors => ['defaults'],
};

sub _build_proxy {
    my ( $class, $name, $arg, $defaults ) = @_;
    my $destination   = $arg->{to} || die "no 'to' given for proxy route";
    my $dest_url      = Mojo::URL->new($destination);
    my $strip_prefix  = $arg->{strip_prefix};
    return sub {
        my $self = shift;
        my $url  = $self->req->url->clone;
        $url->scheme( $dest_url->scheme );
        $url->host( $dest_url->host );
        $url->port( $dest_url->port );
        if ($strip_prefix) {
            my $path = $url->path;
            $path =~ s/^$strip_prefix//;
            $url->path($path);
        }
        my $target = $url->to_string;
        TRACE "proxying ".$self->req->url->to_abs." to ".$url->to_abs;
        LOGDIE "recursive proxy " if $self->req->url->to_abs eq $url->to_abs;
        $self->pause;
        $self->client->get(
            ($target) => sub {
                my ( $client, $tx ) = @_;
                $self->resume;
                $self->render_text( $tx->res->body );
            }
        )->process;
    };
}

1;
