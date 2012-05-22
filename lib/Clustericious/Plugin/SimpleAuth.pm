package Clustericious::Plugin::SimpleAuth;

use Clustericious::Log;
use Mojo::ByteStream qw/b/;
use Mojo::UserAgent;
use Mojo::URL;

use Clustericious::Config;

use warnings;
use strict;

=head1 NAME

Clustericious::Plugin::SimpleAuth - Plugin for clustericious to use simpleauth.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

In the config file :

  "simple_auth" : { "url : "http://simpleauthserver.com:9999" }

In startup() (done by default for all clustericious apps) :

    $app->plugin('simple_auth');

In routes :

 get '/one' => "unprotected";

 authenticate;

 get '/two' => "protected by simpleauth";

 authenticate "Realm";

 get '/three' => "protected by simpleauth, different realm";

 authorize "action", "resource";

 get "/five"; # check for permission to do $action on $resource

 authorize "action";

 get '/four'; # use the url path as the name of the resource

 authorize "<method>";

 get '/six'; # use the request method as the $action, and the url as the path

 authorize "<method>", "/myprefix/<path>";

 get 'seven'; # fill in <path> with request path to compute the resource


=cut

use base 'Mojolicious::Plugin';

sub register_plugin {
    my ($self, $app) = @_;

    1;
}

sub register {

    1;
}

sub authenticate {
    my $self = shift;
    my $c = shift;
    my $realm = shift;

    TRACE ("Authenticating for realm $realm");
    # Everyone needs to send an authorization header
    my $auth = $c->req->headers->authorization or do {
        $c->res->headers->www_authenticate(qq[Basic realm="$realm"]);
        $c->render_text("auth required", layout => "", status => 401);
        return;
    };

    my $config_url = $c->config->simple_auth->url;
    my $ua = Mojo::UserAgent->new;

    my ($method,$str) = split / /,$auth;
    my $userinfo = b($str)->b64_decode;
    my ($user,$pw) = split /:/, $userinfo;

    # VIP treatment for some hosts
    my $ip = $c->tx->remote_address;
    my $tx = $ua->get("$config_url/host/$ip/trusted");
    if ( my $res = $tx->success ) {
        if ( $res->code == 200 ) {
            TRACE "Host $ip is trusted, not authenticating";
            $c->stash( user => $user );
            return 1;
        }
        else {
            WARN "Simpleauth returned code " . $res->code;
        }
    } else {
        my ( $message, $code ) = $tx->error;
        if ($code) {
            TRACE "Host $ip is not a VIP : code $code ($message)";
        } else {
            WARN "Error connecting to simpleauth at $config_url : $message";
        }
    }

    # Everyone else get in line
    my $auth_url = Mojo::URL->new("$config_url/auth");
    $auth_url->userinfo($userinfo);
    $tx = $ua->head($auth_url);
    my $res = $tx->res;
    my $check = $res->code();
    unless (defined($check)) {
        $c->res->headers->www_authenticate(qq[Basic realm="$realm"]);
        WARN ("Error connecting to simpleauth at $config_url");
        $c->render(text => "auth server down", status => 503); # "Service unavailable"
        return 0;
    }
    if ($check == 200) {
        $c->stash(user => $user);
        return 1;
    }
    INFO "Authentication denied for $user, status code : ".$check;
    TRACE "Response was ".$res->to_string;
    $c->res->headers->www_authenticate(qq[Basic realm="$realm"]);
    $c->render(text => "authentication failure", status => 401);
    return 0;
}

sub authorize {
    my $self = shift;
    my $c = shift;
    my ($action,$resource) = @_;
    my $user = $c->stash("user") or LOGDIE "missing user in authorize()";
    LOGDIE "missing action or resource in authorize()" unless @_==2;
    TRACE "Authorizing user $user, action $action, resource $resource";
    $resource =~ s[^/][];
    my $url = Mojo::URL->new( join '/', $c->config->simple_auth->url,
        "authz/user", $user, $action, $resource );
    my $code = Mojo::UserAgent->new->head($url)->res->code;
    return 1 if $code && $code == 200;
    INFO "Unauthorized access by $user to $action $resource";
    $c->render(text => "unauthorized", status => 403);
    return 0;
}

=head1 SEE ALSO

SimpleAuth

=cut

1;
