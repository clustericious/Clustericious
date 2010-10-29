package Clustericious::ClientBuilder;

use strict; no strict 'refs';
use warnings;

=head1 NAME

Clustericious::ClientBuilder - Construct clients for Clustericious apps

=head1 SYNOPSIS

 package Foo::Client;

 use Clustericious::ClientBuilder;

 route 'welcome';                          # Default to GET /

 route status => '/status';                # Default to GET

 route something => GET => '/some/';

 route remove => DELETE => '/something/';

 object 'obj';                             # Defaults to /obj

 object 'foo' => '/something/foo';         # Can override the URL

 # Provide array refs for the command line client to document args
 route something_with_args => GET => "/url/prefix" => [ "<argname1>" ]

 ----------------------------------------------------------------------

 use Foo::Client;

 my $f = Foo::Client->new();
 my $f = Foo::Client->new(server_url => 'http://someurl');
 my $f = Foo::Client->new(app => 'MyApp'); # For testing...

 my $welcome = $f->welcome();              # GET /

 my $status = $f->status();                # GET /status

 my $something = $f->something('this');    # GET /some/this

 $f->remove('foo');                        # DELETE /something/foo

 my $obj = $f->obj('this', 27);            # GET /obj/this/27

 $f->obj({ set => 'this' });               # POST /obj

 $f->obj('this', 27, { set => 'this' });   # POST /obj/this/27

 $f->obj_delete('this', 27);               # DELETE /obj/this/27

 my $obj = $f->foo('this');                # GET /something/foo/this

=head1 DESCRIPTION

Some very simple helper functions with a clean syntax to build a REST
type Client suitable for Clustericious applications.

The builder functions add methods to the client object that translate
into basic REST functions.  All of the 'built' methods return undef on
failure of the REST/HTTP call, and auto-decode the returned body into
a data structure if it is application/json.

=cut

use base 'Mojo::Base';

use Mojo::Client;
use JSON::XS;
use YAML::XS qw(Load Dump LoadFile);
use Clustericious::Config;

=head1 ATTRIBUTES

This class inherits from L<Mojo::Base>, and handles attributes like
that class.  The following additional attributes are used.

=head2 C<client>

A client to process the HTTP stuff with.  Defaults to a
L<Mojo::Client>.

You can use the L<Mojo::Client> asynchronous stuff with callbacks and
$f->client->async and $f->client->process.

=head2 C<app>

For testing, you can specify a Mojolicious app name.

=head2 C<server_url>

You can override the URL prefix for the client, otherwise it
will look it up in the config file.

=head2 C<res>

After an HTTP error, the built methods return undef.  This function
will return the L<Mojo::Message::Response> from the server.

res->code and res->message are the returned HTTP code and message.

=cut

__PACKAGE__->attr(client => sub { Mojo::Client->new });
__PACKAGE__->attr(server_url => '');
__PACKAGE__->attr([qw(app res)]);

our @validObjects;
our @validRoutes;
our %routeArgs;

sub import
{
    my $class = shift;
    my $caller = caller;

    push @{"${caller}::ISA"}, $class;
    *{"${caller}::route"} = \&route;
    *{"${caller}::object"} = \&object;
    *{"${caller}::import"} = sub {};
}

=head1 METHODS

=head2 C<new>

 my $f = Foo::Client->new();
 my $f = Foo::Client->new(server_url => 'http://someurl');
 my $f = Foo::Client->new(app => 'MyApp'); # For testing...

=cut 

sub new
{
    my $self = shift->SUPER::new(@_);

    if ($self->app)
    {
        $self->client->app($self->app);
    }
    elsif (not length $self->server_url)
    {
        (my $appname = ref $self) =~ s/:.*$//;
        $self->server_url(Clustericious::Config->new($appname)->url);
    }
    else
    {
        return undef;
    }
    return $self;
}

=head2 C<errorstring>

 After an error, this returns an error string made up of the
 server error code and message.  (use res->code and res->message to
 get the parts)

 (e.g. "Error: (500) Internal Server Error

=cut

sub errorstring
{
    my $self = shift;
    "Error: (" . $self->res->code . ") " . $self->res->message . "\n";
}

=head1 FUNCTIONS

=head2 C<route>

 route 'subname';                    # GET /
 route subname => '/url';            # GET /url
 route subname => GET => '/url';     # GET /url
 route subname => POST => '/url';    # POST /url

 Makes a method subname() that does the REST action.  Any
 scalar arguments are tacked onto the end of the url.  If you
 pass a hash reference, the method changes to POST and the
 hash is encoded into the body as application/json.

=cut 

sub route
{
    my $subname = shift;
    my $arg_doc = pop if ref $_[-1] eq 'ARRAY';
    my $url     = pop || '/';
    my $method  = shift || 'GET';

    push @validRoutes, $subname;
    $routeArgs{$subname} = $arg_doc;
    *{caller() . "::$subname"} = sub { shift->_doit($method,$url,@_); };
}

=head2 C<object>

 object 'objname';                   # defaults to URL /objname
 object objname => '/some/url';

 Creates two methods, one named with the supplied objname() (used for
 create, retrieve, update), and one named objname_delete().

 Any scalar arguments to the created functions are tacked onto the end
 of the url.  Performs a GET by default, but if you pass a hash
 reference, the method changes to POST and the hash is encoded into
 the body as application/json.

=cut 

sub object
{
    my $objname = shift;
    my $url     = shift || "/$objname";
    my $api     = caller;

    push @validObjects, $objname;
    *{"${api}::$objname"}          = sub { shift->_doit(GET    => $url, @_) };
    *{"${api}::${objname}_delete"} = sub { shift->_doit(DELETE => $url, @_) };
}

sub _doit
 {
    my $self = shift;
    my ($method, $url, @args) = @_;

    $url = $self->server_url . $url if $self->server_url;

    my $cb;
    my $body = '';
    my $headers = {};

    while (my $arg = shift @args)
    {
        if (ref $arg eq 'HASH')
        {
            $method = 'POST';
            $body = encode_json $arg;
            $headers = { 'Content-Type' => 'application/json' };
        }
        elsif (ref $arg eq 'CODE')
        {
            $cb = $self->_mycallback($arg);
        }
        else
        {
            $url .= "/$arg";
        }
    }

    return $self->client->process(
            $self->client->build_tx($method, $url, $headers, $body, $cb) ) if $cb;

    my $tx = $self->client->build_tx($method, $url, $headers, $body);

    $self->client->process($tx);
    $self->res($tx->res);

    return undef unless $tx->res->is_status_class(200);

    return $tx->res->headers->content_type eq 'application/json'
           ? decode_json($tx->res->body)
           : $tx->res->body;
}

sub _mycallback
{
    my $self = shift;
    my $cb = shift;
    sub 
    {
        my ($client, $tx) = @_;

        $self->res($tx->res);

        if ($tx->res->is_status_class(200))
        {
            my $body = $tx->res->headers->content_type eq 'application/json'
                ? decode_json($tx->res->body) : $tx->res->body;

            $cb->($body ? $body : 1);
        }
        else
        {
            $cb->();
        }
    }
}

sub usage {
    my $msg = shift;
    warn "$msg\n\n" if $msg;
    warn "Usage : \n";
    for (@validRoutes) {
      my $argdoc = $routeArgs{$_};
      warn "\t$0 $_". ( $argdoc ? " @$argdoc" : "" ). "\n";
    }
    warn join "\n",
      "\t$0 <object> <keys>",
      "\t$0 create <object> [<filename list>]",
      "\t$0 update <object> <keys> [<filename>]",
      "\t$0 delete <object> <keys>\n";
    warn "\n\tValid objects are : " . ( join ',', @validObjects ). "\n\n";
    die "\n";
}

sub run
{
    my $self = shift;

    my $method = shift @ARGV;

    usage() unless $method;

    if ($method eq 'create')
    {
        $method = shift @ARGV;
        usage("Missing <object>") unless $method;

        usage("Invalid method $method") unless $self->can($method);

        if (@ARGV)
        {
            foreach my $filename (@ARGV)
            {
                my $content = LoadFile($filename)
                    or die "Invalid YAML : $filename\n";
                print "Loading $filename\n";
                $self->$method($content) or warn $self->errorstring;
            }
        }
        else
        {
            my $content = Load(join('', <>))
                or die "Invalid YAML content\n";

            $self->$method($content) or warn $self->errorstring;
        }
        return;
    }

    if ($method eq 'update')
    {
        $method = shift @ARGV;
        usage ("Missing <object>") unless $method;

        my $content;
        if (-r $ARGV[-1])  # Does it look like a filename?
        {
            my $filename = pop @ARGV;
            $content = LoadFile($filename)
                or die "Invalid YAML: $filename\n";
            print "Loading $filename\n";
        }
        else
        {
            $content = Load(join('', <STDIN>))
                or die "Invalid YAML: stdin\n";
        }
        my $ret = $self->$method(@ARGV, $content) or warn $self->errorstring;
        print Dump($ret);
        return;
    }

    if ($method eq 'delete')
    {
        $method = shift @ARGV;
        usage("Missing <object>") unless $method;

        $method .= '_delete';

        usage("Invalid object $method") unless $self->can($method);

        $self->$method(@ARGV) or warn $self->errorstring;
        return;
    }

    if ($self->can($method))
    {
        if (my $obj = $self->$method(@ARGV))
        {
            print Dump($obj);
        }
        else
        {
            warn $self->errorstring;
        }
        return;
    }

    usage ("Invalid arguments");
}

1;

__END__

=head1 TODO

use JsonConfig stuff.
More docs about Mojo::Client async stuff and callbacks..
async testing
also make multiple clients share an ioloop

=cut
