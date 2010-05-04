package Clustericious::Commands;
use File::Basename qw/basename/;
use Clustericious::Config;

use base 'Mojolicious::Commands';
__PACKAGE__->attr(
    namespaces => sub { [qw/Mojolicious::Command Mojo::Command Clustericious::Command/] });

sub start {
   my $self = shift;

   my @args = @_;

   my $config = Clustericious::Config->new;
   use Data::Dumper;
   die Dumper($config);

   # Given $0, use the config file to find the default args
   # Then override using @ARGV,
   # then call self->SUPER::start(@args);

   #  will have to use similar logic to App::_load_config but actually
   #  parse the json files.

   # TODO : make this a method call somewhere
   our @Confdirs = $ENV{TEST_HARNESS} ? 
        ($ENV{CLUSTERICIOUS_TEST_CONF_DIR}) :
        ($ENV{HOME}, "$ENV{HOME}/etc", $self->home, $self->home."/etc",
         "/util/etc", "/etc" );

   # TODO: how do we find our $app_name?
   my $conf_dir = first { -d $_ && -e "$_/$app_name.conf" } @Confdirs
      or die "cannot load config for $app_name";

   my $conf_data = JSON::XS->new->decode("$conf_dir/$app_name.conf");

   my $command = basename $0;
   @args = $conf_data->{$command}{args} unless @ARGV;
   #
   # The conf file should have, e.g.
   #daemon_prefork:
   #    args:[ --listen, <%= $url =%>, --lockfile /tmp/lockfile. ..., -- ]

   $self->SUPER::start(@args);
}


1;

