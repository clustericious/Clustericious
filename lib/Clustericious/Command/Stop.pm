=head1 NAME

Clustericious::Command::Stop

=head1 DESCRIPTION

Stop a running daemon.

=head1 NOTES

The different methods of starting put their pid files in
different places in the config file.   Here are some
examples :

   "hypnotoad" : {
      "pid_file"  : "/tmp/filename.pid",
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

   "nginx" : {
     '-p' : '/home/foo/appname/nginx'
    }

=cut

package Clustericious::Command::Stop;
use Clustericious::Log;
use Clustericious::App;
use Mojo::URL;
use File::Basename qw/dirname/;

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
    -e $pid_file or do { WARN "No pid file $pid_file\n"; return; };
    my $pid = slurp $pid_file; # dies automatically
    chomp $pid;
    _stop_pid($pid,@_);
}

sub _stop_pid {
    my $pid = shift;
    my $signal = shift || 'QUIT';
    unless ($pid && $pid=~/^\d+$/) {
        WARN "Bad pid '$pid'.  Not stopping process.";
        return;
    }
    kill 0, $pid or do { WARN "$pid is not running"; return; };
    INFO "Sending $signal to $pid";
    kill $signal, $pid;
    sleep 1;
    my $nap = 1;
    while (kill 0, $pid) {
        INFO "waiting for $pid";
        sleep $nap++;
        LOGDIE "pid $pid did not die" if $nap > 10;
    }
}

sub _stop_daemon {
    my $listen = shift; # e.g. http://localhost:9123
    my $port = Mojo::URL->new($listen)->port;
    my @got = `lsof -n -FR -i:$port`;
    return unless @got && $got[0];
    # Only the first one; others may be child processes
    my ($pid) = $got[0] =~ /^p(\d+)$/;
    unless ($pid) {
        WARN "could not find pid for daemon on port $port";
        return;
    }
    TRACE "Stopping pid $pid";
    _stop_pid($pid);
}

sub _stop_nginx {
    my %conf = @_;
    my $prefix = $conf{'-p'};
    INFO "stopping nginx in $prefix";
    system("nginx -p $prefix -s quit")==0 or WARN "could not stop nginx";
}

sub _stop_apache {
    my %conf = @_;
    my $prefix = $conf{'-d'};
    INFO "stopping apache in $prefix";
    _stop_pidfile("$prefix/logs/httpd.pid",'TERM');
}

sub run {
    my $self     = shift;
    my $conf     = Clustericious::Config->new( $ENV{MOJO_APP} );

    Clustericious::App->init_logging();

    for (reverse $conf->start_mode) {
        DEBUG "Stopping $_ server";
        /hypnotoad/ and _stop_pidfile($conf->hypnotoad->pid_file(default => dirname($ENV{MOJO_EXE}).'/hypnotoad.pid' ));
        /plackup/   and _stop_pidfile($conf->plackup->pidfile);
        /lighttpd/  and _stop_pidfile($conf->lighttpd->env->lighttpd_pid);
        /daemon/    and _stop_daemon($conf->daemon->listen);
        /nginx/     and _stop_nginx($conf->nginx);
        /apache/    and _stop_apache($conf->apache);
    }

    1;
}

1;

