package Clustericious::Plugin::SimpleAuth;

use Log::Log4perl qw/:easy/;
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
    $c->app->log->trace("Authenticating for realm $realm");
    # TODO
    1;
}

sub authorize {
    my $self = shift;
    my $c = shift;
    my ($action,$resource) = @_;
    $c->app->log->trace("Authorizing action $action, resource $resource");
    # TODO
    1;
}

=head1 SEE ALSO

SimpleAuth

=cut

1;
