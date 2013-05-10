package Clustericious::Plugin::AutodataHandler;

=head1 NAME

Clustericious::Plugin::DataHandler -- Handle data types automatically

=head1 SYNOPSIS

=head1 DESCRIPTION

Adds a renderer that automatically serializes that "autodata" in the
stash into a format based on HTTP Accept and Content-Type headers.
Also adds a helper called 'parse_autodata' that handles incoming data by
Content-Type.

Supports application/json, text/x-yaml and
application/x-www-form-urlencoded (in-bound only).

When parse_autodata is called from within a route like this:

    $self->parse_autodata;

POSTed data is parsed according to the type in the 'Content-Type'
header with the data left in stash->{autodata}.  It is also
returned by the above call.

If a route leaves data in stash->{autodata}, it is rendered by this
handler, which chooses the type with the first acceptable type listed
in the Accept header, the Content-Type header, or the default.  (By
default, the default is application/json, but you can override that
too).

=head1 TODO

more documentation

handle XML with schemas

handle RDF with templates

Should I make this a 'helper' instead of a 'hook'?  Or just a normal
function?

=cut

use strict;
use warnings;

use base 'Mojolicious::Plugin';

use Mojo::ByteStream 'b';
use JSON::XS;
use YAML::XS qw/Dump Load/;

use Clustericious::Log;

our $VERSION = '0.9918';

my $default_decode = 'application/x-www-form-urlencoded';
my $default_encode = 'application/json';

my $json_encoder = JSON::XS->new->allow_nonref->allow_blessed->convert_blessed;

my %types =
(
    'application/json' =>
    {
        encode => sub { $json_encoder->encode($_[0]) },
        decode => sub { $json_encoder->decode($_[0]) }
    },
    'text/x-yaml' =>
    {
        encode => sub { Dump($_[0]) },
        decode => sub { Load($_[0]) }
    },
    'application/x-www-form-urlencoded' =>
    {
        decode => sub { my ($data, $c) = @_; $c->req->params->to_hash }
    }
);

my %formats =
(
    'json' => 'application/json',
    'yml'  => 'text/x-yaml',
);

sub register
{
    my ($self, $app, $conf) = @_;

    $default_decode = $conf->{default_decode} if $conf->{default_decode};
    $default_encode = $conf->{default_encode} if $conf->{default_encode};

    $app->renderer->add_handler('autodata' => \&_autodata_renderer);

    $app->plugins->on( parse_autodata => \&_autodata_parse);
    $app->plugins->on( add_autodata_type => \&_autodata_add);

    $app->helper( parse_autodata => \&_autodata_parse );
}

sub _autodata_add
{
    my($plugins, $args) = @_;

    LOGDIE "No extension provided" unless defined $args->{extension};
    my $ext  = $args->{extension};
    my $mime = $args->{mime_type} // 'application/x-' . $ext;

    $formats{$ext} = $mime;
    
    if(defined $args->{encode}) {
        $types{$mime}->{encode} = $args->{encode};
    }
    
    if(defined $args->{decode}) {
        $types{$mime}->{decode} = $args->{decode};
    }
}

sub _find_type
{
    my ($c) = @_;

    my $headers = $c->tx->req->content->headers;

    foreach my $type (map { /^([^;]*)/ } # get only stuff before ;
                      split(',', $headers->header('Accept') || ''),
                      $headers->content_type || '') {
        return $type if $types{$type} and $types{$type}->{encode};
    }

    my $format = $c->stash->{format} // 'json';
    LOGDIE "No type associated with $format" unless $formats{$format};

    return $formats{$format};
}

sub _autodata_renderer
{
    my ($r, $c, $output, $data) = @_;

    my $type = _find_type($c);
    LOGDIE "no encoder for $type" unless $types{$type}{encode};
    $$output = $types{$type}->{encode}->($c->stash("autodata"), $c);

    $c->tx->res->headers->content_type($type);

    return 1;
}

sub _autodata_parse
{
    my ($c) = @_;

    my $content_type = $c->req->headers->content_type || $default_decode;
    if ($content_type =~ /^([^;]+);/) {
        # strip charset
        $content_type = $1;
    }
    my $entry = $types{$content_type} || $types{$default_decode};

    $c->stash->{autodata} = $entry->{decode}->($c->req->body, $c);
    return $c->stash->{autodata};
}

1;
