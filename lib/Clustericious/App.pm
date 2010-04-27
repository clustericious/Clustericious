package Clustericious::App;

use base 'Mojolicious';
use List::Util qw/first/;
use MojoX::Log::Log4perl;
use warnings;
use strict;

our @Confdirs;

sub startup {
    my $self = shift;
    our @Confdirs = $ENV{TEST_HARNESS} ? 
        ($ENV{CLUSTERICIOUS_TEST_CONF_DIR}) :
        ($ENV{HOME}, "$ENV{HOME}/etc", $self->home, $self->home."/etc",
         "/util/etc", "/etc" );

    $self->_init_logging();

    my $config = $self->_load_config();
    $self->_load_service_configs($config);

    my $r = $self->routes;
    Clustericious::RouteBuilder->add_routes($self);
}

sub _init_logging {
    my $self = shift;

    # Logging
    $ENV{LOG_LEVEL} ||= ( $ENV{HARNESS_ACTIVE} ? "WARN" : "DEBUG" );

    my $app_name = lc ref $self;

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
    warn "# Using $l4p_dir/log4perl.conf for log config\n" if $l4p_dir;
}

sub _load_config {
    my $self = shift;
    our @Confdirs;
    my $app_name = $_[0] || lc ref $self;
    my $stash_key = @_ ? "config_$app_name" : "config";
    my $conf_dir = first { -d $_ && -e "$_/$app_name.conf" } @Confdirs
      or die "cannot load config for $app_name";
    warn "# Using $conf_dir/$app_name.conf for $app_name\n";
    return $self->plugin( 'json_config',
        { file => "$conf_dir/$app_name.conf", stash_key => $stash_key } );
}

sub _load_service_configs {
    my ($self,$config) = @_;
    for (@{ $config->{services} }) {
        next if $_->{url};
        my $service = $_->{name};
        $self->_load_config($service);
    }
}

sub service {

    $self->plugins->namespaces(['Clustericious::Plugin']);
    $self->plugin('data_handler');
}

1;
