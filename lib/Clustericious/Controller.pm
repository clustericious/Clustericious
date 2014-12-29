package Clustericious::Controller;

use strict;
use warnings;
use Clustericious::Config;
use Clustericious::Log;
use base 'Mojolicious::Controller';

# ABSTRACT: Clustericious controller base class
our $VERSION = '0.9940_04'; # VERSION


sub url_for {
    my $c = shift;

    # link_to calls url_for on a Mojo::URL which for some reason
    # causes /a/b?c=d to not work properly (? is escaped)
    return $_[0] if @_==1 && ref($_[0]) eq "Mojo::URL";

    my $base = $c->config->url_base( default => '' );
    my $url = $c->SUPER::url_for(@_);
    return $url unless $base;
    $url->base->parse($base);
    return $url;
}


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
    $self->helpers->reply->not_found
}


sub render_exception { shift->helpers->reply->exception(@_) }


sub render_text { shift->render( text => @_ ) };
sub render_json { shift->render( json => @_ ) };

1;


__END__
=pod

=head1 NAME

Clustericious::Controller - Clustericious controller base class

=head1 VERSION

version 0.9940_04

=head1 SYNOPSIS

 use base qw( Clustericious::Controller );

=head1 DESCRIPTION

Base class for all controllers in Clustericious applications

=head1 SUPER CLASS

L<Mojolicious::Controller>

=head1 METHODS

=head2 $c-E<gt>url_for

Clustericious version of this method usually provided by Mojolicious.

=head2 redirect_to

Copied from Mojolicious::Controller, but works around
a limitation of Apache's mod_proxy (namely: the ProxyPassReverse
directive doesn't handle authorization information in the
Location header.)

It does this by explicitly using the url_base from the
Clustericious config file for the app as the base for
the location header.

=head2 $c-E<gt>render_not_found

Clustericious version of this method usually provided by Mojolicious.

=head2 $c-E<gt>render_exception($message)

Clustericious version of this method usually provided by Mojolicious.

=head2 $c-E<gt>render_text

Previous versions of Mojolicious included this
method, and it was added here to ease the transition.  This method should be considered
deprecated and may be removed in the future.

=head2 $c-E<gt>render_json

Previous versions of Mojolicious included this
method, and it was added here to ease the transition.  This method should be considered
deprecated and may be removed in the future.

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

