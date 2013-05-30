
=head1 NAME

Clustericious::Templates -- default templates for clustericious

=head1 DESCRIPTION

This package contains some default templates (inline) for clustericious.
Anything on the filesystem (in templates/) will override these.

=cut

package Clustericious::Templates;

our $VERSION = '0.9921';

1;

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




