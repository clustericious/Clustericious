package Clustericious::Plugin::SimpleAuth;

use Clustericious::Log;
use Mojo::ByteStream qw/b/;
use Mojo::UserAgent;
use Mojo::URL;

use Clustericious::Config;
use Mojo::Base 'Mojolicious::Plugin';

use warnings;
use strict;

=head1 NAME

Clustericious::Plugin::SimpleAuth - Plugin for clustericious to use simpleauth.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

SimpleApp.conf:

 {"simple_auth":{"url":"http://simpleauthserver:3000"}}

Application:

 package SimpleApp;
 
 use base qw( Clustericious::App );
 
 sub startup {
   my $self = shift;
   $self->SUPER::startup(@_);
   # done by default for all clustericious applications.
   #$self->plugin('simple_auth');
 }
 
 package SimpleApp::Routes;
 
 use Clustericious::RouteBuilder;

 # unprotected 
 get '/public' => 'unprotected';
 
 # requires simpleauth username/password
 authenticate; 
 get '/private1' => 'protected';
 
 # protected by simple auth using an explicit realm
 autheticate 'realm';
 get '/private2' => 'realm protected';
 
 # check for permissions to do $action on $resource
 authorize 'action', 'resource';
 get '/restricted1' => 'authz_restricted';
 
 # check for premissions to do $action on the resource /restricted2
 authorize 'action';
 get '/restricted2';
 
 # HTTP method as the $action and /http_method_get as the resource
 authorize '<method>';
 get '/http_method_get';

 # HTTP method as the $action and "/prefix/http_method_with_prefix"
 # as the resource.
 authorize '<method>', '/myprefix/<path>';
 get '/http_method_with_prefix';

=head1 DESCRIPTION

This provides authenticate and authorize methods which can be called from your applications
Route class.

=cut

sub register_plugin {
    my ($self, $app) = @_;

    $app->hook(after_dispatch => sub { Clustericious::Plugin::SimpleAuth->skip_auth(0) });

    1;
}

sub register {

    1;
}

=head1 METHODS

=head2 authenticate [ $realm ]

Require username and password authentication, optionally with a realm.
If a realm is not provided, '' is used.

=cut

sub authenticate {
    my $self = shift;
    my $c = shift;
    my $realm = shift;
    return 1 if $self->skip_auth;

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

    my $self_simple_auth = ref($c->app) =~ /^(?:Simple|Plug)Auth$/;

    # VIP treatment for some hosts
    my $ip = $c->tx->remote_address;
    my $tx = $self_simple_auth ? $c->subdispatch(GET => "$config_url/host/$ip/trusted") : $ua->get("$config_url/host/$ip/trusted");
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

    my $check;
    my $res;
    if($self_simple_auth) {
        $check = $c->data->check_credentials($user, $pw) ? 200 : 401;
    } else {
        $tx = $ua->head($auth_url);
        $res = $tx->res;
        $check = $res->code();
    }
    if(!defined $check || $check == 503) {
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
    TRACE "Response was ".$res->to_string if defined $res;
    $c->res->headers->www_authenticate(qq[Basic realm="$realm"]);
    $c->render(text => "authentication failure", status => 401);
    return 0;
}

=head2 authorize [$action, [$resource]]

Require the authenticated user have the authorization to perform
the given action on the given resource.

=cut

sub authorize {
    my $self = shift;
    my $c = shift;
    return 1 if $self->skip_auth;
    my ($action,$resource) = @_;
    my $user = $c->stash("user") or LOGDIE "missing user in authorize()";
    LOGDIE "missing action or resource in authorize()" unless @_==2;
    TRACE "Authorizing user $user, action $action, resource $resource";
    $resource =~ s[^/][];
    my $url = Mojo::URL->new( join '/', $c->config->simple_auth->url,
        "authz/user", $user, $action, $resource );
    my $code = (ref($c->app) =~ /^(?:Simple|Plug)Auth$/ ? $c->subdispatch(HEAD => $url) : Mojo::UserAgent->new->head($url))->res->code;
    return 1 if $code && $code == 200;
    INFO "Unauthorized access by $user to $action $resource";
    if($code == 503) {
        $c->render(text => "auth server down", status => 503); # "Service unavailable"
    } else {
        $c->render(text => "unauthorized", status => 403);
    }
    return 0;
}

=head2 skip_auth

 Clustericious::Plugin::SimpleAuth->skip_auth(1);

Set this global flag to bypass authentication and authorization, e.g. during
a subequest.  This flag is reset at the end of the dispatch cycle.

=cut

sub skip_auth {
    state $skip_auth = 0;
    my $class = shift;
    return $skip_auth unless @_;
    $skip_auth = shift;
    return $skip_auth;
}

=head1 SEE ALSO

L<SimpleAuth>

=cut

1;
