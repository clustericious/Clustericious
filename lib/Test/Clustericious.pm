package Test::Clustericious;

use strict;
use warnings;

=head1 NAME

Test::Clustericious - Test Clustericious apps

=head1 SYNOPSIS

 use Test::Clustericious;

 my $t = Test::Clustericious(app => 'SomeMojoApp');

 my $t = Test::Clustericious(server => 'myapp');

 my $t = Test::Clustericious(server_url => 'http://foo'); 

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
use YAML::Syck;
use File::Slurp qw/slurp/;
use Carp;
use List::Util qw(first);

=head1 ATTRIBUTES

=head2 C<server>

 my $t = Test::Clustericious->new(server => 'MyServer');

 Looks up the URI for the server in the config file ...

=head2 C<server_url>

 my $t = Test::Clustericious->new(server_url => 'http://foo/');

 Explicitly define a server url to test against.

=cut

__PACKAGE__->attr('server');
__PACKAGE__->attr('server_url');

=head1 METHODS

=head2 C<testdata>

 my $object = $t->testdata('filename');

 Looks for filename, filename.json, filename.yaml in 't' or 'eg' 
 directories.  Parses with json or yaml if appropriate, then 
 returns the object.

=cut

sub testdata
{
    my $self = shift;
    my ($filename) = @_;

    $filename = first { -r }
                $filename, "t/$filename", "eg/$filename",
                "$filename.json", "$filename.yaml",
                "t/$filename.json", "t/$filename.yaml",
                "eg/$filename.json", "eg/$filename.yaml";

    my $content = slurp($filename) or croak "Missing $filename";
    
    return decode_json($content) if $filename =~ /json$/;

    return Load($content) if $filename =~ /yaml$/;

    return $content;
}

sub url
{
    my $self = shift;
    my ($url) = @_;

    return $url if not defined $self->{server_url}
                   or $url =~ /^$self->{server_url}/;

    return $self->{server_url} ? "$self->{server_url}$url" : $url;    
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

 if called with a filename, loads the object from the file as
 described in testdata().

 Uses POST to the url to create the object, encoded with JSON.
 Checks for status 200 and returns the decoded body.

 This counts as 2 TAP tests.

=cut

sub create_ok
{
    my $self = shift;
    my ($url, $object) = @_;

    $url = $self->url($url);

    unless (ref $object)
    {
        $object = $self->testdata($object) or return;
    }

    $self->post_ok($url,
                   { "Content-Type" => "application/json" },
                   encode_json($object),
                   "Create $url")
         ->status_is(200, "Created $url")
         ->decoded_body;
}

=head2 C<retrieve_ok>

 $obj = $t->retrieve_ok('/url');

 GETs the url, checks for status 200, and returns the decoded body.

 This counts as 2 TAP tests.

=cut

sub retrieve_ok
{
    my $self = shift;
    my ($url) = @_;
    
    $url = $self->url($url);

    $self->get_ok($url, '', "GET $url")
         ->status_is(200, "GET $url status is 200")
         ->decoded_body;
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

    $url = $self->url($url);

    $self->delete_ok($url, '', "DELETE $url")
         ->status_is(200, "deleted $url status is 200" )
         ->content_is("ok", "Deleted $url content is ok")
         ->notfound_ok($url);
}

=head2 C<notfound_ok>

 $t->notfound_ok($url);

 GETs the url and checks for a 404 Not found return.

 This counts as 3 TAP tests.

=cut

sub notfound_ok
{
    my $self = shift;
    my ($url) = @_;

    $url = $self->url($url);

    $self->get_ok($url, '', "GET $url")
         ->status_is(404, "$url status is 404")
         ->content_like(qr/Not found/i, "$url content is Not Found");
}

1;

__END__

=head1 SEE ALSO

L<Clustericious>

=cut