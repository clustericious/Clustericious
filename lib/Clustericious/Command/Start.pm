=head1 NAME

Clustericious::Command::Start

=head1 DESCRIPTION

Stop a daemon using the config file and the start_mode.

=head1 NOTES

For a prefork daemon, the config file should
contain "daemonize" and "pid" keys, e.g. :

   "start_mode" : "daemon_prefork",
   "daemon_prefork" : {
      "daemonize": 1,
      "pid"      : "/tmp/restmd.pid",
      ....
    }

=cut

package Clustericious::Command::Start;
use Log::Log4perl qw/:easy/;
use File::Slurp qw/slurp/;
use List::MoreUtils qw/mesh/;

use Clustericious::App;
use Clustericious::Config;
use base 'Mojo::Command';

use strict;
use warnings;

__PACKAGE__->attr(description => <<EOT);
Start a daemon using the config file.
EOT

__PACKAGE__->attr(usage => <<EOT);
usage $0: start
Start a daemon using the start_mode in the config file.
See Clustericious::Config for the format of the config file.
EOT

sub run {
    my $self     = shift;
    my @args = @_ ? @_ : @ARGV;
    my $conf     = Clustericious::Config->new( $ENV{MOJO_APP} );

    Clustericious::App->init_logging;

    my $mode = $conf->start_mode;
    INFO "Starting in mode $mode";

    my %args = mesh
      @{ [ map "--$_", keys %{ $conf->$mode } ] },
      @{ [ values %{ $conf->$mode } ] };

    $ENV{MOJO_COMMANDS_DONE} = 0;
    Mojolicious::Commands->start($mode,%args);
}


1;

