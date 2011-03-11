=head1 NAME

Clustericious::App -- base class for clustericious apps

=head1 DESCRIPTION

Inherits from Mojolicious, add adds the following functionality :

=over

=cut

package Clustericious::App;

use List::Util qw/first/;
use List::MoreUtils qw/uniq/;
use MojoX::Log::Log4perl;
use Mojo::Client;
use Clustericious::Templates;
use base 'Mojolicious';

use Clustericious::Controller;
use Clustericious::RouteBuilder::Common;
use Clustericious::Config;

use warnings;
use strict;

our @Confdirs = $ENV{TEST_HARNESS} ?
   ($ENV{CLUSTERICIOUS_TEST_CONF_DIR}) :
   ($ENV{HOME}, "$ENV{HOME}/etc", "/util/etc", "/etc" );

=item startup

Adds the data_handler plugin, common routes,
and sets up logging for the client using log::log4perl.

=cut

sub startup {
    my $self = shift;

    $self->renderer->default_template_class("Clustericious::Templates");
    $self->controller_class('Clustericious::Controller');
    $self->init_logging();
    $self->secret( (ref $self || $self) );

    my $r = $self->routes;
    # "Common" ones are not overrideable.
    Clustericious::RouteBuilder::Common->add_routes($self);
    Clustericious::RouteBuilder->add_routes($self);
    # "default" ones are :
    # Clustericious::RouteBuilder::Default->add_routes($self);

    $self->plugins->namespaces(['Clustericious::Plugin']);
    $self->plugin('data_handler');
    my $config = Clustericious::Config->new(ref $self);
    if ($config->simple_auth(default => '')) {
        $self->log->info("Loading auth plugin");
        $self->plugin('simple_auth');
    } else {
        $self->log->info("No auth configured");
    }
    if (my $base = $config->url_base(default => '')) {
        $self->helper( url_for =>
              sub { my $url = shift->url_for(@_);
                    $url->base->parse($base);
                    $url;
                 } );
        $self->helper( base_tag => sub { qq[<base href="$base" />] } );
    }
    unless (my $url = $config->url(default => '')) {
        $self->log->warn("Configuration file should contain 'url'.") unless $ENV{HARNESS_ACTIVE};
    }
    $self->helper( config => sub { $config } );
    my $client = Mojo::Client->singleton;
    $client->log($self->log);
}

=item init_logging

Initializing logging using ~/etc/log4perl.conf

=cut

sub init_logging {
    my $self = shift;

    # Logging
    $ENV{LOG_LEVEL} ||= ( $ENV{HARNESS_ACTIVE} ? "WARN" : "DEBUG" );

    my $app_name = lc ref $self || $ENV{MOJO_APP};

    my $l4p_dir; # dir with log config file.
    my $l4p_pat; # pattern for screen logging

    if ($ENV{HARNESS_ACTIVE}) {
        $l4p_pat = "# %5p: %m%n";
    } else  {
        $l4p_dir  = first { -d $_ && -e "$_/log4perl.conf"  } @Confdirs;
        $l4p_pat  = "[%d] [%Z %H %P] %5p: %m%n";
    }

    Log::Log4perl::Layout::PatternLayout::add_global_cspec('Z', sub {$app_name});

    my $logger = MojoX::Log::Log4perl->new( $l4p_dir ? "$l4p_dir/log4perl.conf":
      { # default config
       ($ENV{LOG_FILE} ? (
          "log4perl.rootLogger"              => "$ENV{LOG_LEVEL}, File1",
          "log4perl.appender.File1"          => "Log::Log4perl::Appender::File",
          "log4perl.appender.File1.layout"   => "PatternLayout",
          "log4perl.appender.File1.filename" => "$ENV{LOG_FILE}",
          "log4perl.appender.File1.layout.ConversionPattern" => "[%d] [%Z %H %P] %5p: %m%n",
        ):(
          "log4perl.rootLogger"               => "$ENV{LOG_LEVEL}, SCREEN",
          "log4perl.appender.SCREEN"          => "Log::Log4perl::Appender::Screen",
          "log4perl.appender.SCREEN.layout"   => "PatternLayout",
          "log4perl.appender.SCREEN.layout.ConversionPattern" => "$l4p_pat",
       )),
      # These categories (%c) are too verbose by default :
       "log4perl.logger.Mojolicious"                     => "WARN",
       "log4perl.logger.Mojolicious.Plugin.RequestTimer" => "WARN",
       "log4perl.logger.MojoX.Dispatcher.Routes"         => "WARN",
    });
    $self->log( $logger );

    $self->log->debug("Initialized logger to level ".$self->log->level);
    $self->log->debug("Log config found in $l4p_dir/log4perl.conf") if $l4p_dir;
    # warn "# started logging ($l4p_dir/log4perl.conf)\n" if $l4p_dir;
}

=item dump_api

Dump out the API for this REST server.

=cut

sub dump_api {
    my $self = shift;
    my $routes = shift || $self->routes->children;
    my @all;
    for my $r (@$routes) {
        my $pat = $r->pattern;
        $pat->_compile;
        my %symbols = map { $_ => "<$_>" } @{ $pat->symbols };
        my %conditions = @{ $r->conditions };
        my $method = uc join ',', @{ $r->via || ["GET"] };
        if ($symbols{table}) {
            for my $table (Rose::Planter->tables) {
                $symbols{table} = $table;
                my $pat = $pat->pattern;
                $pat =~ s/:table/$table/;
                push @all, "$method $pat";
            }
        } elsif ($symbols{items}) {
            for my $plural (Rose::Planter->plurals) {
                $symbols{items} = $plural;
                my $line = $pat->render(\%symbols);
                push @all, "$method $line";
            }
        } elsif (defined($pat->pattern)) {
            push @all, join ' ', $method, $pat->pattern;
        } else {
            push @all, $self->dump_api($r->children);
        }
    }
    return uniq sort @all;
}

1;
