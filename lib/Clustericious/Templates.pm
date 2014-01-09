package Clustericious::Templates;

use strict;
use warnings;

# ABSTRACT: default templates for clustericious
our $VERSION = '0.9935'; # VERSION


1;



=pod

=head1 NAME

Clustericious::Templates - default templates for clustericious

=head1 VERSION

version 0.9935

=head1 DESCRIPTION

This package contains some default templates (inline) for clustericious.
Anything on the filesystem (in templates/) will override these.

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


__DATA__

@@ not_found.html.ep
NOT FOUND :  "<%= $self->req->url->path || '/' %>"

@@ not_found.development.html.ep
NOT FOUND :  "<%= $self->req->url->path || '/' %>"

@@ layouts/default.html.ep
<!doctype html><html>
    <head><title>Welcome</title></head>
    <body><%== content %></body>
</html>

@@ exception.html.ep
% my $s = $self->stash;
% my $e = $self->stash('exception');
% delete $s->{inner_template};
% delete $s->{exception};
% my $dump = dumper $s;
% $s->{exception} = $e;
% use Mojo::ByteStream qw/b/;
ERROR:
<%= b($e); %>




