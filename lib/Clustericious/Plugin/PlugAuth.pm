package Clustericious::Plugin::PlugAuth;

use strict;
use warnings;
use Clustericious::Log;
use Mojo::ByteStream qw/b/;
use Mojo::URL;
use Mojo::Base 'Mojolicious::Plugin';

# ABSTRACT: Plugin for clustericious to use PlugAuth.
# VERSION

=head1 SYNOPSIS

MyApp.conf:

 ---
 plug_auth:
   url: http://plugauthserver:3000

Application:

 package MyApp;
 
 use base qw( Clustericious::App );
 use Clustericious::RouteBuilder;

 # unprotected 
 get '/public' => 'unprotected';
 
 # require PlugAuth username/password
 authenticate; 
 get '/private1' => 'protected';
 
 # protected by PlugAuth an explicit realm
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

=head1 ATTRIBUTES

=head2 config_url

The URL of the PlugAuth server to authenticate against.

=cut

has 'config_url';

sub register {
    my ($self, $app, $conf) = @_;
    eval { $self->config_url($conf->{plug_auth}->url(default => '')) };
    if ($@ || !$self->config_url) {
        WARN "unable to determine PlugAuth URL: $@";
        return $self;
    }
    $self;
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

    TRACE ("Authenticating for realm $realm");
    # Everyone needs to send an authorization header
    my $auth = $c->req->headers->authorization or do {
        $c->res->headers->www_authenticate(qq[Basic realm="$realm"]);
        $c->render(text => "auth required", layout => "", status => 401);
        return;
    };

    my $config_url = $self->config_url;

    my ($method,$str) = split / /,$auth;
    my $userinfo = b($str)->b64_decode;
    my ($user,$pw) = split /:/, $userinfo;

    my $self_plug_auth = 0;

    # VIP treatment for some hosts
    my $ip = $c->tx->remote_address;
    $c->ua->get("$config_url/host/$ip/trusted", sub {
        my $ua = shift;
    
        do {
            my $tx = shift;
            if ( my $res = $tx->success ) {
                if ( $res->code == 200 ) {
                    TRACE "Host $ip is trusted, not authenticating";
                    $c->stash( user => $user );
                    $c->continue;
                    return;
                }
                else {
                    WARN "PlugAuth returned code " . $res->code;
                }
            } else {
                my ( $message, $code ) = $tx->error;
                if ($code) {
                    TRACE "Not VIP $config_url/host/$ip/trusted : $code $message";
                } else {
                    WARN "Error connecting to PlugAuth at $config_url/host/$ip/trusted : $message";
                }
            }
        };

        # Everyone else get in line
        my $auth_url = Mojo::URL->new("$config_url/auth");
        $auth_url->userinfo($userinfo);

        my $check;
        my $res;

        $ua->head($auth_url, sub {
 
            my($ua, $tx) = @_;

            $res = $tx->res;
            $check = $res->code();

            if(!defined $check || $check == 503) {
                $c->res->headers->www_authenticate(qq[Basic realm="$realm"]);
                my ( $message, $code ) = $tx->error;
                if ($code) {
                    WARN "Error connecting to PlugAuth at $auth_url : $code $message";
                } else {
                    WARN "Error connecting to PlugAuth at $auth_url : $message";
                }
                $c->render(text => "auth server down", status => 503); # "Service unavailable"
                return;
            }
            if ($check == 200) {
                $c->stash(user => $user);
                $c->continue;
                return;
            }
            INFO "Authentication denied for $user, status code : ".$check;
            TRACE "Response was ".$res->to_string if defined $res;
            $c->res->headers->www_authenticate(qq[Basic realm="$realm"]);
            $c->render(text => "authentication failure", status => 401);
        });
    
    });

    return undef;
}

=head2 authorize [$action, [$resource]]

Require the authenticated user have the authorization to perform
the given action on the given resource.

=cut

sub authorize {
    my $self = shift;
    my $c = shift;
    my ($action,$resource) = @_;
    my $user = $c->stash("user") or LOGDIE "missing user in authorize()";
    LOGDIE "missing action or resource in authorize()" unless @_==2;
    TRACE "Authorizing user $user, action $action, resource $resource";

    $resource =~ s[^/][];

    my $url = Mojo::URL->new( join '/', $self->config_url, "authz/user", $user, $action, $resource );

    my $tx = $c->ua->build_tx(HEAD => $url);
    
    $c->ua->start($tx, sub {
        my($ua, $tx) = @_;
        
        my $code = $tx->res->code;
        if($code && $code == 200) {
            $c->continue;
            return;
        }
        
        INFO "Unauthorized access by $user to $action $resource";
        if($code == 503) {
            $c->render(text => "auth server down", status => 503); # "Service unavailable"
        } else {
            $c->render(text => "unauthorized", status => 403);
        }
    });

    return undef;
}

=head1 SEE ALSO

L<PlugAuth>, L<Clustericious>

=cut

1;
