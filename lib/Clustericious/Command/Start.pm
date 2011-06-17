=head1 NAME

Clustericious::Command::Start

=head1 DESCRIPTION

Start a daemon using the config file and the start_mode.

=head1 EXAMPLE

For hypnotoad, the config file should
contain "daemonize" and "pid" keys, e.g. :

   "start_mode" : "hypnotoad",
   "hypnotoad" : {
      "pid"      : "/tmp/restmd.pid",
      [...]
      "env"      : {
        "foo" : "bar"
      }
    }

The above configuration will will cause "app start"
to be equivalent to

  foo=bar MyApp.pl daemon_preform --daemonize 1 --id /tmp/restmd.pid [..]

In other words, keys and values in the configuration file become
options preceded by double dashes.

If a key has a single dash, it is sent as is (with no double dash).

The special value "null" means don't send an argument to the
command line option  (e.g. --daemonize)

The special label "env" is an optional hash of environment variables
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
See Clustericious::Command::Start for examples.
EOT

sub run {
    my $self     = shift;
    my @args = @_ ? @_ : @ARGV;
    my $app  = $ENV{MOJO_APP};
    my $conf     = Clustericious::Config->new( $app );

    local $SIG{__DIE__} = \&Carp::confess;
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
        @ENV{ keys %$env } = values %$env;
        if ($env->{PERL5LIB}) {
            # Do it now, in case we are not spawning a new process.
            push @INC, split /:/, $env->{PERL5LIB};
        }
        TRACE "Setting env vars : ".join ',', keys %$env;

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

