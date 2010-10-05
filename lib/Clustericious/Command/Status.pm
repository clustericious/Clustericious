=head1 NAME

Clustericious::Command::Status

=head1 DESCRIPTION

Report the status of a running clustericious daemon, based on its start_mode.

=cut

package Clustericious::Command::Status;
use Log::Log4perl qw/:easy/;
use Mojo::Client;

use Clustericious::App;
use Clustericious::Config;
use base 'Mojo::Command';

use strict;
use warnings;

__PACKAGE__->attr(description => <<'');
Report the status of a daemon.

__PACKAGE__->attr(usage => <<"");
usage: $0 status
Report the status of a clustericious daemon.

sub _check_pidfile {
    my $filename = shift;

    return ( state => 'error', message => 'missing pid filename' ) unless $filename;
    return ( state => 'down', message => 'no pid file' ) unless -e $filename;
    my $pid = Mojo::Asset::File->new(path => $filename)->slurp;
    return ( state => 'down', messasge => 'no pid in file' ) unless $pid;
    return ( state => 'ok' ) if kill 0, $pid;
    return ( state => 'down', message => "Pid $pid in file is not running." );
}

sub run {
    my $self = shift;
    my @args = @_ ? @_ : @ARGV;
    my $app  = $ENV{MOJO_APP};
    my $conf = Clustericious::Config->new($app);

    my @status;
    for ($conf->start_mode) {
        push @status, { name => $_,
         ( /daemon_prefork/ ? _check_pidfile($conf->daemon_prefork->pid)
         : /plackup/        ? _check_pidfile($conf->plackup->pidfile) 
         : /lighttpd/       ? _check_pidfile($conf->lighttpd->env->lighttpd_pid)
         : ( state => 'error', message => "Status for start_mode $_ is unimplemented." ))};
    }
    # Send as YAML if requested?
    my $ok = 0;
    for (@status) {
        $_->{message} &&= "($_->{message})";;
        $_->{message} ||= "";
        printf "%10s : %-10s %s\n", @$_{qw/name state message/};
        $ok++ if $_->{state} eq 'ok';
    }
    if ($ok==@status) {
        my $res = Mojo::Client->new->get($conf->url)->res;
        printf qq[%10s : %-10s (%d %s)\n], "url", $conf->url, $res->code, $res->message;
    }
}

1;

