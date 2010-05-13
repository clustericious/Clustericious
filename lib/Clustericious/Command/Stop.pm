=head1 NAME

Clustericious::Command::Stop

=head1 DESCRIPTION

Stop a running daemon.

=head1 NOTES

For a prefork daemon, the config file should
contain "daemonize" and "pid" keys, e.g. :

   "daemon_prefork" : {
      "daemonize": 1,
      "pid"      : "/tmp/restmd.pid",
      ....
    }

=cut

package Clustericious::Command::Stop;
use Log::Log4perl qw/:easy/;
use Clustericious::App;

use base 'Mojo::Command';
use Clustericious::Config;
use File::Slurp qw/slurp/;

use strict;
use warnings;

__PACKAGE__->attr(description => <<EOT);
Stop a running daemon.
EOT

__PACKAGE__->attr(usage => <<EOT);
usage $0: stop

There are no options available.  It will send a TERM signal to
the running daemon, if there is one.
EOT

sub run {
    my $self     = shift;
    my $conf     = Clustericious::Config->new( $ENV{MOJO_APP} );

    Clustericious::App->init_logging();

    my $pid_file = $conf->daemon_prefork->pid
      or LOGDIE "no pid file in conf file";
    -e $pid_file or LOGDIE "No pid file $pid_file\n";
    my $pid = slurp $pid_file; # dies automatically
    kill 0, $pid or LOGDIE "$pid is not running";
    INFO "Stopping server ($pid)";
    kill 'TERM', $pid;
    sleep 1;
    my $nap = 1;
    # Seem like Mojo::Server::Daemon::Prefork should do this.
    while (kill 0, $pid) {
        INFO "waiting for $pid";
        sleep $nap++;
        LOGDIE "pid $pid did not die" if $nap > 10;
    }
    1;
}

1;

