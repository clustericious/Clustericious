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
      ...
      "env"      : {
        "foo" : "bar"
      }
    }

Tthe label "env" is an optional hash of environment variables
to set before starting the command.

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
    my $app  = $ENV{MOJO_APP};
    my $conf     = Clustericious::Config->new( $app );

    eval "use $app;";
    if ($@) {
        die "\n----------Error loading $app----------\n$@\n--------------\n";
    }

    Clustericious::App->init_logging;

    for my $mode ($conf->start_mode) {
        #  local %ENV = %ENV;
        INFO "Starting $mode";
        my %conf = $conf->$mode;

        # env hash goes to the environment
        my $env = delete $conf{env} || {};
        use Data::Dumper;
        warn Dumper(\%conf);
        @ENV{ keys %$env } = values %$env;

        # if it starts with a dash, leave it alone, else add two dashes
        my %args = mesh
          @{ [ map {/^-/ ? "$_" : "--$_"} keys %conf ] },
          @{ [ values %conf                          ] };

        # squash "null"s (for boolean arguments)
        my @args = grep { $_ ne 'null' } %args;
        DEBUG "Sending args for $mode : @args";

        $ENV{MOJO_COMMANDS_DONE} = 0;
        Clustericious::Commands->start($mode,@args);
    }
}


1;

