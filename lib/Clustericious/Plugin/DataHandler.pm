package Clustericious::Plugin::DataHandler;

=head1 NAME

Clustericious::Plugin::DataHandler -- Handle data types automatically

=head1 SYNOPSIS

=head1 DESCRIPTION

Replaces the Mojolicious 'data' renderer with one that automatically
renders outputs by type based on HTTP Accept and Content-Type headers.
Also adds a hook called 'parse_data' that handles incoming data by
Content-Type.

Supports application/json, text/x-yaml and
application/x-www-form-urlencoded (in-bound only).

When hook 'parse_data' is called from within a route like this:

 $self->app->plugins->run_hook('parse_data', $self);

POSTed data is parsed according to the type in the 'Content-Type'
header with the data left in stash->{data}.

If a route leaves data in stash->{data}, it is rendered by this
handler, which chooses the type with the first acceptable type listed
in the Accept header, the Content-Type header, or the default.  (By
default, the default is application/json, but you can override that
too).

=head1 TODO

more documentation

handle XML with schemas

handle RDF with templates

Should I make a new renderer name rather than stealing 'data'?

Should I make this a 'helper' instead of a 'hook'?  Or just a normal
function?

=cut

use strict;
use warnings;

use base 'Mojolicious::Plugin';

use Mojo::ByteStream 'b';
use JSON::XS;
use YAML::Syck; $YAML::Syck::Headless = 1;

my $default_decode = 'application/x-www-form-urlencoded';
my $default_encode = 'application/json';

my %types = 
(
    'application/json' => 
    {
        encode => sub { encode_json($_[0]) },
        decode => sub { decode_json($_[0]) }
    },
    'text/x-yaml' =>
    {
        encode => sub { YAML::Syck::Dump($_[0]) },
        decode => sub { YAML::Syck::Load($_[0]) }
    },
    'application/x-www-form-urlencoded' =>
    {
        decode => sub { my ($data, $c) = @_; $c->req->params->to_hash }
    }
);

sub register
{
    my ($self, $app, $conf) = @_;

    $default_decode = $conf->{default_decode} if $conf->{default_decode};
    $default_encode = $conf->{default_encode} if $conf->{default_encode};

    $app->renderer->add_handler('data' => \&_data_render);

    $app->plugins->add_hook(parse_data => \&_data_parse);
}

sub _find_type
{
    my ($headers) = @_;

    foreach my $type (map { /^([^;]*)/ } # get only stuff before ;
                      split(',', $headers->header('Accept') || ''),
                      $headers->content_type || '')
                       
    {
        return $type if $types{$type} and $types{$type}->{encode};
    }

    return $default_encode;
}

sub _data_render
{
    my ($r, $c, $output, $data) = @_;

    my $type = _find_type($c->tx->req->content->headers);

    $$output = $types{$type}->{encode}->($data->{data}, $c);

    $c->tx->res->headers->content_type($type);

    return 0;
}

sub _data_parse
{
    my ($self, $c) = @_;

    my $type = ($c->req->headers->content_type and
                $types{$c->req->headers->content_type})
               ? $c->req->headers->content_type
               : $default_decode;

    $c->stash->{data} = $types{$type}->{decode}->($c->req->body, $c);
}

1;
