package Test::Clustericious;

use strict;
use warnings;

# ABSTRACT: Test Clustericious apps
our $VERSION = '0.9940_04'; # VERSION


use base 'Test::Mojo';

use JSON::XS;
use YAML::XS;
use File::Slurp qw/slurp/;
use Carp;
use List::Util qw(first);
use Clustericious::Config;

require Test::More;


__PACKAGE__->attr('server');
__PACKAGE__->attr('server_url');


sub new
{
    my $class = shift;
    shift @_ if (@_==2 && $_[0] eq 'app'); # allow deprecated app => 'foo'
    my $self = $class->SUPER::new(@_);

    if ($self->app)
    {
        $self->server_url('');
    }
    elsif ($self->server)
    {
        $self->server_url(Clustericious::Config->new($self->server)->url);
    }
    else
    {
        return undef unless $self->server_url;
    }

    return $self;
}


sub testdata
{
    my $self = shift;
    my ($filename) = @_;

    $filename = first { -r }
                map { $_, "$_.yaml", "$_.json" }
                map { $_, "t/$_", "data/$_", "t/data/$_" }
                $filename;

    my $content = slurp($filename) or croak "Missing $filename";

    return decode_json($content) if $filename =~ /json$/;

    return Load($content) if $filename =~ /yaml$/;

    return $content;
}

sub _url
{
    my $self = shift;
    my ($url) = @_;

    my $server_url = $self->server_url;
    return $url if $url =~ /^$server_url/;
    return $server_url . $url;
}


sub decoded_body
{
    my $self = shift;

    my $res = $self->tx->res;

    my $body = $res->body;

    if ($res->headers->content_type and
        $res->headers->content_type eq 'application/json')
    {
        $body = decode_json($body);
    }

    return $res->is_status_class(200) ? $body : undef;
}


sub create_ok
{
    my $self = shift;
    my $url = shift;

    if (@_ > 1)
    {
        $self->create_ok($url, $_) for @_;
        return;
    }

    my $object = shift;

    $url = $self->_url($url);

    unless (ref $object)
    {
        $object = $self->testdata($object) or return;
    }

    $self->post_ok($url, json => $object, "Create $url")
         ->status_is(200, "Created $url")
         ->decoded_body;
}


sub update_ok { create_ok(@_) }


sub retrieve_ok
{
    my $self = shift;
    my ($url) = @_;
    
    $url = $self->_url($url);

    $self->get_ok($url, '', "GET $url");
    my $res = $self->tx->res;
    Test::More::ok ($res->is_status_class(200), "GET $url status is 200");
    return $self->decoded_body;
}


sub remove_ok
{
    my $self = shift;
    my ($url) = @_;

    $url = $self->_url($url);

    $self->delete_ok($url, '', "DELETE $url")
         ->status_is(200, "deleted $url status is 200" )
         ->content_is("ok", "Deleted $url content is ok")
         ->notfound_ok($url);
}


sub notfound_ok
{
    my $self = shift;
    my ($url, $object) = @_;

    $url = $self->_url($url);

    if ($object)
    {
        $self->post_ok($url, { "Content-Type" => "application/json" },
                       encode_json($object), "POST $url");
    }
    else
    {
        $self->get_ok($url);
    };

    $self->status_is(404, "$url status is 404")
         ->content_like(qr/(Not found|null)/i, "$url content is null or Not Found");
}


# Should probably do this directly on the server side for speed,
# but this way is fun..

sub truncate_ok
{
    my $self = shift;
    my ($url) = @_;

    while (1)
    {
        my $list = $self->retrieve_ok($url) or return;

        return unless @$list;

        foreach my $key (@$list)
        {
            $self->remove_ok("$url/$key") or return;
        }
    }
}

1;



=pod

=head1 NAME

Test::Clustericious - Test Clustericious apps

=head1 VERSION

version 0.9940_04

=head1 SYNOPSIS

 use Test::Clustericious;

 my $t = Test::Clustericious->new(app => 'SomeMojoApp');
 my $t = Test::Clustericious->new(server => 'myapp');
 my $t = Test::Clustericious->new(server_url => 'http://foo');

 my $obj = $t->create_ok('/my/url', { my => 'object' }); # 2 tests

 my $obj = $t->retrieve_ok('/url/id'); # 2 tests, returns decoded object

 $t->update_ok('/url/id', { my => 'object' }); # 2 tests

 $t->remove_ok('/url/id'); # 6 tests: deletes, then gets to verify gone

=head1 DESCRIPTION

L<Test::Clustericious> is a collection of testing helpers for everyone
developing L<Clustericious> applications.  It inherits from
L<Test::Mojo>, and add the following new attributes and methods.

=head1 ATTRIBUTES

=head2 C<server>

 my $t = Test::Clustericious->new(server => 'MyServer');

Looks up the URL for the server in the config file for the
specified server.

=head2 C<server_url>

 my $t = Test::Clustericious->new(server_url => 'http://foo/');

Explicitly define a server url to test against.

=head1 METHODS

=head2 C<new>

 my $t = Test::Clustericious(app => 'SomeMojoApp');
 my $t = Test::Clustericious(server => 'myapp');
 my $t = Test::Clustericious(server_url => 'http://foo'); 

=head2 C<testdata>

 my $object = $t->testdata('filename');

Looks for filename, filename.json, filename.yaml in 't', 'data' or
't/data' directories.  Parses with json or yaml if appropriate, then
returns the object.

=head2 C<decoded_body>

 $obj = $t->decoded_body;

Returns the body from the last request, parsing with JSON if
Content-Type is application/json.

Returns undef if the parse fails or the last request wasn't status
2xx.

=head2 C<create_ok>

 $obj = $t->create_ok('/url', { some => 'object' });
 $obj = $t->create_ok('/url', 'filename');
 $t->create_ok('/url', <many/files*>);

if called with a filename, loads the object from the file as
described in testdata().

Uses POST to the url to create the object, encoded with JSON.
Checks for status 200 and returns the decoded body.

You can also create multiple objects/files at once, but then there is
no returned object.

This counts as 2 TAP tests.

=head2 C<update_ok>

 update_ok is really just an alias for create_ok

=head2 C<retrieve_ok>

 $obj = $t->retrieve_ok('/url');

Makes a GET request on the url, checks for status 200, and returns the 
decoded body.

This counts as 2 TAP tests.

=head2 C<remove_ok>

 $t->remove_ok($url);

Makes a DELETE request on the url, checks for status 200 and content of 
'ok'.  Then does a GET of the same url and checks for not found.

This counts as 6 TAP tests.

=head2 C<notfound_ok>

 $t->notfound_ok($url[, $object]);

Makes a GET request on the url, or if $object specified, a POST request 
the encoded object and checks for a 404 response code and "not found" or 
"null".

This counts as 3 TAP tests.

=head2 C<truncate_ok>

 $t->truncate_ok($url);

Makes a GET request the URL, which should return a list of keys, then 
iterates over the list and delete_ok() each one.

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


__END__

