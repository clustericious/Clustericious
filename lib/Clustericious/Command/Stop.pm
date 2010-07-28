=head1 NAME

Clustericious::Command::Stop

=head1 DESCRIPTION

Stop a running daemon.

=head1 NOTES

The different methods of starting put their pid files in
different places in the config file.   Here are some
examples :

   "daemon_prefork" : {
      "daemonize": 1,
      "pid"      : "/tmp/filename.pid",
      ....
    }

   "plackup" : {
      "pidfile"   : "/tmp/nother_filename.pid",
      "daemonize" : "null"    # means include "--daemonize"
   ...
   },

   "lighttpd" : {
      "env" : {
          "lighttpd_pid"    : "/tmp/third_filename.pid"
           ...
      },
   },

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

Send a TERM signal to running daemon(s).
See Clustericious::Command::Stop.
EOT

sub _stop_pidfile {
    my $pid_file = shift;
    -e $pid_file or LOGDIE "No pid file $pid_file\n";
    my $pid = slurp $pid_file; # dies automatically
    chomp $pid;
    unless ($pid && $pid=~/\d/) {
        WARN "pid file $pid_file had '$pid'.  Not stopping process.";
        return;
    }
    kill 0, $pid or LOGDIE "$pid is not running";
    INFO "Sending TERM to $pid (in $pid_file)";
    kill 'TERM', $pid;
    sleep 1;
    my $nap = 1;
    while (kill 0, $pid) {
        INFO "waiting for $pid";
        sleep $nap++;
        LOGDIE "pid $pid did not die" if $nap > 10;
    }
}

sub run {
    my $self     = shift;
    my $conf     = Clustericious::Config->new( $ENV{MOJO_APP} );

    Clustericious::App->init_logging();

    for (reverse $conf->start_mode) {
        /daemon_prefork/ and _stop_pidfile($conf->daemon_prefork->pid);
        /plackup/        and _stop_pidfile($conf->plackup->pidfile);
        /lighttpd/       and _stop_pidfile($conf->lighttpd->env->lighttpd_pid);
    }

    1;
}

1;

