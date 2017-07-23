package Clustericious::App;

use strict;
use warnings;
use 5.010;
use List::Util qw( first );
use MojoX::Log::Log4perl;
use Mojo::UserAgent;
use Data::Dumper;
use Clustericious::Log;
use Mojo::URL;
use Scalar::Util qw( weaken );
use Mojo::Base 'Mojolicious';
use File::HomeDir ();
use Carp qw( croak carp );
use Clustericious;
use Clustericious::Controller;
use Clustericious::Config;
use Clustericious::Commands;
use Path::Class::Dir;

# ABSTRACT: Clustericious app base class
# VERSION

=head1 SYNOPSIS

 use Mojo::Base 'Clustericious::App';
 
=head1 DESCRIPTION

This class is the base class for all Clustericious applications.  It
inherits everything from L<Mojolicious> and adds a few Clustericious
specific methods documented here.

=head1 SUPER CLASS

L<Mojolicious>

=head1 ATTRIBUTES

=head2 commands

An instance of L<Clustericious::Commands> for use with this application.

=cut

has commands => sub {
  my $commands = Clustericious::Commands->new(app => shift);
  weaken $commands->{app};
  return $commands;
};

=head1 METHODS

=head2 startup

 $app->startup;

Adds the autodata_handler plugin, common routes,
and sets up logging for the client using log::log4perl.

=cut

sub startup {
    my $self = shift;

    $self->init_logging();
    $self->plugins->namespaces(['Clustericious::Plugin','Mojolicious::Plugin']);
    $self->controller_class('Clustericious::Controller');
    $self->renderer->classes(['Clustericious::App']);

    # this is questionable
    my $home = $self->home;
    $self->renderer->paths([ Path::Class::Dir->new($home)->subdir('templates')->stringify ]);

    $self->plugin('CommonRoutes');
    $self->plugin('AutodataHandler');
    $self->plugin('ClustericiousHelpers');

    @{ $self->static->paths } = (
      Clustericious
        ->_dist_dir
        ->subdir(qw( www 1.08 ))
        ->stringify
    );

    my $config = $self->config;
    my $auth_plugin;
    if(my $auth_config = $config->plug_auth(default => '')) {
        $self->log->info("Loading auth plugin plug_auth");
        my $name = 'plug_auth';
        if(ref($auth_config) && $auth_config->{plugin})
        { $name = $auth_config->{plugin} }
        $auth_plugin = $self->plugin($name, plug_auth => $auth_config);
    } else {
        $self->log->info("No auth configured");
    }

    $self->startup_route_builder($auth_plugin) if $self->can('startup_route_builder');

    my $url = $config->url(default => '') or do {
        $self->log->warn("Configuration file should contain 'url'.");
    };

    $self->hook( before_dispatch => sub {
        Log::Log4perl::MDC->put(remote_ip => shift->tx->remote_address || 'unknown');
    });

    if ( my $cors_allowed_origins = $config->cors_allowed_origins( default => '' ) ) {
        $self->hook(
            after_dispatch => sub {
                my $c = shift;
                $c->res->headers->add( 'Access-Control-Allow-Origin' => $cors_allowed_origins );
                $c->res->headers->add( 'Access-Control-Allow-Headers' => 'Authorization' );
            }
        );
    }

}

=head2 init_logging

 $app->init_logging;

Initializing logging using ~/etc/log4perl.conf

=cut

sub init_logging {
    my $self = shift;
    croak "cannot be called as class method" unless ref $self;
    my $logger = Clustericious::Log->init_logging($self);
    $self->log( $logger );
}

=head2 config

 my $config = $app->config;

Returns the config (an instance of L<Clustericious::Config>) for the application.

=cut

sub config
{
  my($self, $what) = @_;

  unless($self->{_config})
  {
    my $config = $self->{_config} = eval { Clustericious::Config->new(ref $self) };
    if(my $error = $@)
    {
      $self->log->error("error loading config $error");
      $config = $self->{_config} = Clustericious::Config->new({ clustericious_config_error => $error });
    }

    $config->{url} //= Clustericious->_default_url(ref $self);
    
    if(grep { $_ eq 'hypnotoad' } $config->start_mode(default => [ 'hypnotoad' ]) )
    {
      my $hypnotoad = $config->hypnotoad(
        default => sub {
          my $url = Mojo::URL->new($config->{url});
          {
            pid_file => File::Spec->catfile( File::HomeDir->my_dist_data("Clustericious", { create => 1 } ), 'hypnotoad-' . $url->port . '-' . $url->host . '.pid' ),
            listen => [
              $url->to_string,
            ],
          };
        }
      );
    }
  }

  my $config = $self->{_config};

  # Mojo uses $app->config('what');
  # Clustericious usually uses $app->config->what;
  $what ? $config->{$what} : $config;
}

=head2 sanity_check

 my $ok = $app->sanity_check;

This method is executed after C<startup>, but before the application
actually starts with the L<start|Clustericious::Command::start> command.
If it returns 1 then the configuration is considered sane and the 
application will start.  If it returns 0 then the configuration has
problems and start will be aborted with an appropriate message to the user
attempting start.

By default this just checks that the application's configuration file
(usually located in ~/etc/MyApp.conf) is correctly formatted as either
YAML or JSON.

You can override this in your application, but don't forget to call
the base class's version of sanity_check before making your own checks.

=cut

sub sanity_check
{
  my($self) = @_;
  my $sane = 1;
  
  if(my $error = $self->config->clustericious_config_error(default => ''))
  {
    say "error loading configuration: $error";
    $sane = 0;
  }
    
  $sane;
}

1;

=head1 SEE ALSO

L<Clustericious>

=cut

__DATA__

@@ not_found.html.ep
NOT FOUND: "<%= $self->req->url->path || '/' %>"

@@ not_found.development.html.ep
NOT FOUND: "<%= $self->req->url->path || '/' %>"

@@ layouts/default.html.ep
<!doctype html><html>
  <head><title>Welcome</title></head>
  <body><%== content %></body>
</html>

@@ exception.html.ep
% my $s = $self->stash;
% my $e = $self->stash('exception');
% delete $s->{inner_template};
% delete $s->{exception};
% my $dump = dumper $s;
% $s->{exception} = $e;
% use Mojo::ByteStream qw/b/;
ERROR: <%= b($e); %>

