package Clustericious::App;

use base 'Mojolicious';
use List::Util qw/first/;
use MojoX::Log::Log4perl;
use warnings;
use strict;

our @Confdirs = $ENV{TEST_HARNESS} ?
   ($ENV{CLUSTERICIOUS_TEST_CONF_DIR}) :
   ($ENV{HOME}, "$ENV{HOME}/etc", "/util/etc", "/etc" );

sub startup {
    my $self = shift;

    $self->init_logging();

    my $r = $self->routes;
    Clustericious::RouteBuilder->add_routes($self);

    $self->plugins->namespaces(['Clustericious::Plugin']);
    $self->plugin('data_handler');
}

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

    $self->log->info("Initialized logger to level ".$self->log->level);
    $self->log->info("Log config found in $l4p_dir/log4perl.conf") if $l4p_dir;
    warn "# started logging ($l4p_dir/log4perl.conf)\n" if $l4p_dir;
}

1;
