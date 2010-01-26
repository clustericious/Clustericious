package Clustericious::Node;

use base 'Mojolicious';
use MojoX::Log::Log4perl;
use Sys::Hostname qw/hostname/;

sub startup {
    my $self = shift;

    # Logging
    $ENV{LOG_LEVEL} ||= ( $ENV{HARNESS_ACTIVE} ? "WARN" : "DEBUG" );

    # NB: allow a conf file
    my $logger = MojoX::Log::Log4perl->new( {
      "log4perl.rootLogger"               => "$ENV{LOG_LEVEL}, SCREEN",
      "log4perl.appender.SCREEN"          => "Log::Log4perl::Appender::Screen",
      "log4perl.appender.SCREEN.layout"   => "PatternLayout",
      "log4perl.appender.SCREEN.layout.ConversionPattern" => "[%d] [%H:%P] [%5p] %m%n",
      # %c will show the category, to add things like :
      # "log4perl.logger.Mojolicious.Plugin.RequestTimer" => "ERROR"
    });
    $self->log( $logger );

    my $host = hostname;
    $self->log->info("Initialized logger for $host $$ to level ".$self->log->level);

    my $r = $self->routes;
    Clustericious::RouteManager->add_routes($r);

}

1;

