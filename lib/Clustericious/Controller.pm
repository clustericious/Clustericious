package Clustericious::Controller;

use strict;
use warnings;
use Clustericious::Config;
use Clustericious::Log;
use Carp qw( carp );
use base 'Mojolicious::Controller';

# ABSTRACT: Clustericious controller base class
# VERSION

=head1 SYNOPSIS

 use base qw( Clustericious::Controller );

=head1 DESCRIPTION

Base class for all controllers in Clustericious applications

=head1 SUPER CLASS

L<Mojolicious::Controller>

=head1 METHODS

=head2 url_for

Clustericious version of this method usually provided by Mojolicious.

=cut

sub url_for {
    my $c = shift;

    # NOTE: the only place it looks like we need to use this bizzarely 
    # customized url_for is in Restmd.  If we can confirm/deny that we
    # do/don't need it there, then we can probably remove this special case
    # NOTE2: also used in the function below.

    # Note: This dos not seem to be the case anymore:
    # Original Comment: link_to calls url_for on a Mojo::URL which for some reason
    # causes /a/b?c=d to not work properly (? is escaped)
    return $_[0] if @_==1 && ref($_[0]) eq "Mojo::URL";

    my $base = $c->config->url_base( default => '' );
    my $url = $c->SUPER::url_for(@_);
    return $url unless $base;
    $url->base->parse($base);
    return $url;
}

=head2 redirect_to

Copied from Mojolicious::Controller, but works around
a limitation of Apache's mod_proxy (namely: the ProxyPassReverse
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

1;

=head1 SEE ALSO

L<Clustericious>

=cut
