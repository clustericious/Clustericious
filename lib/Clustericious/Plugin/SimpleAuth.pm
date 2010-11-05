package Clustericious::Plugin::SimpleAuth;

use Log::Log4perl qw/:easy/;
use Mojo::ByteStream qw/b/;
use Mojo::Client;
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

 get "/five"; # => check for permission to do $action on $resource

 authorize "action";

 get '/four'; # => "use the url path as the name of the resource".

=cut

use base 'Mojolicious::Plugin';

sub register_plugin {
    my ($self, $app) = @_;

    1;
}

sub authenticate {
    my $self = shift;
    my $c = shift;
    my $realm = shift;
    TRACE ("Authenticating for realm $realm");
    my $auth = $c->req->headers->authorization or do {
        $c->res->headers->www_authenticate("Basic '$realm'");
        $c->render(text => "auth required", status => 401);
        return;
    };
    my ($method,$str) = split / /,$auth;
    my $userinfo = b($str)->b64_decode;
    my ($user,$pw) = split /:/, $userinfo;
    my $config_url = $c->config->simple_auth->url;
    my $auth_url = Mojo::URL->new("$config_url/auth");
    $auth_url->userinfo($userinfo);
    my $client = Mojo::Client->singleton;
    my $check = $client->head($auth_url)->res->code();
    unless (defined($check)) {
        WARN ("Error connecting to simple auth at $config_url");
        $c->render(text => "auth server down", status => 403);
        return 0;
    }
    if ($check == 200) {
        $c->stash(user => $user);
        return 1;
    }
    INFO "Authentication denied for $user";
    $c->render(text => "authentication failure", status => 403);
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
    my $code = Mojo::Client->singleton->head($url)->res->code;
    return 1 if $code && $code == 200;
    INFO "Unauthorized access by $user to $action $resource";
    $c->render(text => "unauthorized", status => 403);
    return 0;
}

=head1 SEE ALSO

SimpleAuth

=cut

1;