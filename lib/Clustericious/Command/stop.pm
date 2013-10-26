package Clustericious::Command::stop;

use strict;
use warnings;
use Clustericious::Log;
use Clustericious::App;
use Mojo::URL;
use File::Basename qw/dirname/;
use base 'Clustericious::Command';
use Clustericious::Config;
use File::Slurp qw/slurp/;

# ABSTRACT: Clustericious command to stop a Clustericious application
our $VERSION = '0.9931'; # VERSION


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
    TRACE "pid_file : $pid_file";
    my $pid = slurp $pid_file; # dies automatically
    chomp $pid;
    TRACE "file $pid_file has pid $pid";
    _stop_pid($pid,@_);
    -e $pid_file or return;
    unlink $pid_file or WARN "Could not remove $pid_file";
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
    my $cnf = $conf{'-c'} || "";
    $cnf = "-c $cnf" if $cnf;
    INFO "stopping nginx in $prefix";
    system("nginx -p $prefix $cnf -s quit")==0 or WARN "could not stop nginx";
}

sub _stop_apache {
    my %conf = @_;
    my $prefix = $conf{'-d'};
    INFO "stopping apache in $prefix";
    _stop_pidfile("$prefix/logs/httpd.pid",'TERM');
}

sub run {
    my $self     = shift;
    exit 2 unless $self->app->sanity_check;
    my $conf     = Clustericious::Config->new( $ENV{MOJO_APP} );

    Clustericious::App->init_logging();

    my $exe = $0;
    for (reverse $conf->start_mode) {
        DEBUG "Stopping $_ server";
        /hypnotoad/ and _stop_pidfile($conf->hypnotoad->pid_file(default => dirname($exe).'/hypnotoad.pid' ));
        /plackup/   and _stop_pidfile($conf->plackup->pidfile);
        /lighttpd/  and _stop_pidfile($conf->lighttpd->env->lighttpd_pid);
        /daemon/    and _stop_daemon($conf->daemon->listen);
        /nginx/     and _stop_nginx($conf->nginx);
        /apache/    and _stop_apache($conf->apache);
    }

    1;
}

1;


__END__
=pod

=head1 NAME

Clustericious::Command::stop - Clustericious command to stop a Clustericious application

=head1 VERSION

version 0.9931

=head1 SYNOPSIS

 % yourapp stop

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

=head1 AUTHOR

original author: Brian Duggan

current maintainer: Graham Ollis <plicease@cpan.org>

contributors:

Curt Tilmes

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

