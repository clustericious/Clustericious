package Clustericious::App;

use strict;
use warnings;
use 5.010;
use List::Util qw( first );
use MojoX::Log::Log4perl;
use Mojo::UserAgent;
use Mojo::ByteStream qw( b );
use Data::Dumper;
use Clustericious::Log;
use Mojo::URL;
use Scalar::Util qw( weaken );
use Mojo::Base 'Mojolicious';
use File::HomeDir ();
use Carp qw( cluck croak carp );
use Clustericious;
use Clustericious::Controller;
use Clustericious::Config;
use Clustericious::Commands;

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

=cut

# TODO: moved into CommonRoutes
sub _have_rose {
  return 1 if Rose::Planter->can("tables");
}

=head1 ATTRIBUTES

=head2 commands

An instance of L<Clustericious::Commands> for use with this application.

=cut

has commands => sub {
  my $commands = Clustericious::Commands->new(app => shift);
    weaken $commands->{app};
    return $commands;
};

{
no warnings 'redefine';
sub Math::BigInt::TO_JSON {
    my $val = shift;
    my $copy = "$val";
    my $i = 0 + $copy;
    return $i;
}
}

=head1 METHODS

=head2 startup

 $app->startup;

Adds the autodata_handler plugin, common routes,
and sets up logging for the client using log::log4perl.

=cut

sub startup {
    my $self = shift;

    @{ $self->static->paths } = (
      Clustericious
        ->_dist_dir
        ->subdir(qw( www 1.08 ))
        ->stringify
    );

    $self->controller_class('Clustericious::Controller');
    $self->renderer->classes(['Clustericious::App']);
    my $home = $self->home;
    $self->renderer->paths([ $home->rel_dir('templates') ]);

    $self->init_logging();
    $self->secrets( [ ref $self || $self ] );

    $self->plugins->namespaces(['Clustericious::Plugin','Mojolicious::Plugin']);
    my $config = $self->config;
    my $auth_plugin;
    if(my $auth_config = $config->plug_auth(default => '')) {
        $self->log->info("Loading auth plugin plug_auth");
        my $name = 'plug_auth';
        if(ref($auth_config) && $auth_config->{plugin})
        { $name = $auth_config->{plugin} }
        $auth_plugin = $self->plugin($name, plug_auth => $auth_config);
    } elsif($auth_config = $config->simple_auth(default => '')) {
        croak "Using simple_auth in configuration has been removed.  Change your configuration to use plug_auth instead.";
    } else {
        $self->log->info("No auth configured");
    }

    $self->plugin('CommonRoutes');
    $self->startup_route_builder($auth_plugin) if $self->can('startup_route_builder');
    $self->plugin('AutodataHandler');
    
    #
    $self->plugin('DefaultHelpers');
    #$self->plugin('TagHelpers');
    $self->plugin('EPLRenderer');
    $self->plugin('EPRenderer');

    # Helpers
    if (my $base = $config->url_base(default => '')) {
        $self->helper( base_tag => sub { b( qq[<base href="$base" />] ) } );
    }
    my $url = $config->url(default => '') or do {
        $self->log->warn("Configuration file should contain 'url'.");
    };

    $self->helper( url_with => sub {
        my $c = shift;
        my $q = $c->req->url->clone->query;
        my $url = $c->url_for->clone;
        $url->query($q);
        $url;
    });

    $self->helper( auth_ua => sub { shift->ua } );

    $self->helper( render_moved => sub {
        my $c = shift;
        $c->res->code(301);
        my $where = $c->url_for(@_)->to_abs;
        $c->res->headers->location($where);
        $c->render(text => "moved to $where");
    } );

    # See http://groups.google.com/group/mojolicious/browse_thread/thread/000e251f0748c997
    my $murl = Mojo::URL->new($url);
    my $part_count = @{ $murl->path->parts };
    if ($part_count > 0 ) {
        $self->hook(before_dispatch  => sub {
            my $c = shift;
            if (@{ $c->req->url->base->path->parts } > 0) {
                # subrequest
                my @extra = splice @{ $c->req->url->base->path->parts }, -$part_count;
            }
            push @{ $c->req->url->base->path->parts },
              splice @{ $c->req->url->path->parts }, 0, $part_count;
        });
    }

    $self->hook( before_dispatch => sub {
        Log::Log4perl::MDC->put(remote_ip => shift->tx->remote_address || 'unknown');
    });

    if ( my $cors_allowed_origins = $config->cors_allowed_origins( default => '*' ) ) {
        $self->hook(
            after_dispatch => sub {
                my $c = shift;
                $c->res->headers->add( 'Access-Control-Allow-Origin' => '*' );
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

    my $logger = Clustericious::Log->init_logging(ref $self || $self);

    # Can no longer use log as a class method
    $self->log( $logger ) if ref $self;
}

=head2 dump_api

 my @api = $app->dump_api;

B<DEPRECATED>: will be removed on or after January 31, 2016.

Dump out the API for this REST server.

=cut

sub dump_api {
  carp "Clustericious::App#dump_api is deprecated";
  require Clustericious::Plugin::CommonRoutes;
  Clustericious::Plugin::CommonRoutes->_dump_api(@_);
}

=head2 dump_api_table

 my $api = $app->dump_api_table( $table );

B<DEPRECATED>: will be removed on or after January 31, 2016.

Dump out the column information for the given table.

=cut

sub _dump_api_table_types
{
  carp "Clustericious::App#dump_api_table is deprecated";
  require Clustericious::Plugin::CommonRoutes;
  Clustericious::Plugin::CommonRoutes->_dump_api_table_types(@_);
  
}

sub dump_api_table
{
  carp "Clustericious::App#dump_api_table is deprecated";
  require Clustericious::Plugin::CommonRoutes;
  Clustericious::Plugin::CommonRoutes->_dump_api_table($_[1]);
}

=head2 config

 my $config = $app->config;

Returns the config (an instance of L<Clustericious::Config>) for the application.

=cut

sub config {
  my($self, $what) = @_;

  unless($self->{_config})
  {
    my $config = $self->{_config} = eval { Clustericious::Config->new(ref $self) };
    if(my $error = $@)
    {
      $self->log->error("error loading config $error");
      $config = $self->{_config} = Clustericious::Config->new({ clustericious_config_error => $error });
    }

    if($config->{url})
    {
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

