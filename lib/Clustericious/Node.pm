package Clustericious::Node;

use base 'Mojolicious';
use MojoX::Log::Log4perl;

sub startup {
    my $self = shift;

    # Logging
    $ENV{LOG_LEVEL} ||= ( $ENV{HARNESS_ACTIVE} ? "WARN" : "DEBUG" );

    my $name = ref $self;

    # NB: allow a conf file
    my $logger = MojoX::Log::Log4perl->new( {
      "log4perl.rootLogger"               => "$ENV{LOG_LEVEL}, SCREEN",
      "log4perl.appender.SCREEN"          => "Log::Log4perl::Appender::Screen",
      "log4perl.appender.SCREEN.layout"   => "PatternLayout",
      "log4perl.appender.SCREEN.layout.ConversionPattern" => "[%d] [$name %H %P] %5p: %m%n",
      # %c will show the category, to add things like :
       "log4perl.logger.Mojolicious.Plugin.RequestTimer" => "ERROR",
      # "log4perl.logger.Mojolicious" => "ERROR",
       "log4perl.logger.Mojolicious.Plugin.RequestTimer" => "ERROR",
       "log4perl.logger.MojoX.Dispatcher.Routes" => "ERROR",
      # "log4perl.logger.Restmd" => "ERROR",
      # "log4perl.logger.Mojo.Server.Daemon" => "ERROR",
    });
    $self->log( $logger );

    $self->log->info("Initialized logger to level ".$self->log->level);

    my $r = $self->routes;
    Clustericious::RouteBuilder->add_routes($self);

}

1;

