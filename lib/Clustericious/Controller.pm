package Clustericious::Controller;
use Clustericious::Config;
use Log::Log4perl qw/:easy/;

use base 'Mojolicious::Controller';
use strict;
use warnings;

=head1 redirect_to

Copied from Mojolicious::Controller, but works around
a limitation of apache's mod_proxy (namely: the ProxyPassReverse
directive doesn't handle authorization information in the
Location header.)

It does this by explicitly using the url_base from the
Clustericious config file for the app as the base for
the location header.

=cut

sub redirect_to {
    my $self = shift;

    # Response
    my $res = $self->res;

    # Code
    $res->code(302);

    # Headers
    my $headers = $res->headers;
    my $loc = $self->url_for(@_);

    if (my $url_base = Clustericious::Config->new(ref $self->app)->url_base(default => '')) {
        $loc->base->parse($url_base);
    }

    $headers->location($loc->to_abs);
    $headers->content_length(0);

    # Rendered
    $self->rendered;

    return $self;
}

sub render_not_found {
    my $self = shift;
    undef $self->stash->{autodata} if exists($self->stash->{autodata});
    $self->SUPER::render_not_found(@_);
}

1;

