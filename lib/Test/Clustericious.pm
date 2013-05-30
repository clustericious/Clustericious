package Test::Clustericious;

use strict;
use warnings;

our $VERSION = '0.9921';

=head1 NAME

Test::Clustericious - Test Clustericious apps

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

=cut

use base 'Test::Mojo';

use JSON::XS;
use YAML::XS;
use File::Slurp qw/slurp/;
use Carp;
use List::Util qw(first);
use Clustericious::Config;

require Test::More;

=head1 ATTRIBUTES

=head2 C<server>

 my $t = Test::Clustericious->new(server => 'MyServer');

 Looks up the URL for the server in the config file for the
 specified server.

=head2 C<server_url>

 my $t = Test::Clustericious->new(server_url => 'http://foo/');

 Explicitly define a server url to test against.

=cut

__PACKAGE__->attr('server');
__PACKAGE__->attr('server_url');

=head1 METHODS

=head2 C<new>

 my $t = Test::Clustericious(app => 'SomeMojoApp');
 my $t = Test::Clustericious(server => 'myapp');
 my $t = Test::Clustericious(server_url => 'http://foo'); 

=cut

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

=head2 C<testdata>

 my $object = $t->testdata('filename');

 Looks for filename, filename.json, filename.yaml in 't', 'data' or
 't/data' directories.  Parses with json or yaml if appropriate, then
 returns the object.

=cut

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

=head2 C<decoded_body>

 $obj = $t->decoded_body;

 Returns the body from the last request, parsing with JSON if
 Content-Type is application/json.

 Returns undef if the parse fails or the last request wasn't status
 2xx.

=cut 

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

=cut

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

=head2 C<update_ok>

 update_ok is really just an alias for create_ok

=cut

sub update_ok { create_ok(@_) }

=head2 C<retrieve_ok>

 $obj = $t->retrieve_ok('/url');

 GETs the url, checks for status 200, and returns the decoded body.

 This counts as 2 TAP tests.

=cut

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

=head2 C<remove_ok>

 $t->remove_ok($url);

 DELETEs the url, checks for status 200 and content of 'ok'.  Then
 does a GET of the same url and checks for not found.

 This counts as 6 TAP tests.

=cut

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

=head2 C<notfound_ok>

 $t->notfound_ok($url[, $object]);

 GETs the url, or if $object specified, POSTs the encoded object
 and checks for a 404 response code and "not found" or "null".

 This counts as 3 TAP tests.

=cut

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

=head2 C<truncate_ok>

 $t->truncate_ok($url);

 GETs the URL, which should return a list of keys, then iterates
 over the list and delete_ok() each one.

=cut

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

__END__

=head1 SEE ALSO

L<Clustericious>

=cut
