=head1 NAME

Clustericious::Command::status - Clustericious command to report status of Clustericious application

=head1 SYNOPSIS

 % yourapp status

=head1 DESCRIPTION

Report the status of a running clustericious daemon, based on its start_mode.

=head1 SUPER CLASS

L<Clustericious::Command>

=head1 SEE ALSO

L<Clustericious>

=cut

package Clustericious::Command::status;
use Clustericious::Log;
use Mojo::UserAgent;

use Clustericious::App;
use Clustericious::Config;
use File::Basename qw/dirname/;
use base 'Clustericious::Command';

use strict;
use warnings;

our $VERSION = '0.9925';

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

sub _check_database {
    my $db_class = shift;
    my $db = $db_class->new_or_cached;
    my ( $domain, $type ) = ( $db->default_domain, $db->default_type );
    my $dbh = $db->dbh;
    my ( $state, $message );
    if ($dbh) {
        $state = 'ok';
        ($message) = join ':', grep {defined && length}
          $dbh->selectrow_array(
            q[select current_database(), inet_server_addr(), inet_server_port()]
          );
    }
    else {
        $state   = 'down';
        $message = $db_class->name;
    }
    return +{
        name    => "database",
        state   => $state,
        message => "$domain:$type $message",
    };
}

sub run {
    my $self = shift;
    my @args = @_ ? @_ : @ARGV;
    my $app  = $ENV{MOJO_APP};
    my $conf = Clustericious::Config->new($app);

    eval "require $app";
    die "Could not load $app : \n$@\n" if $@;

    my @status; # array of { name =>.., state =>.., message =>.. } hashrefs.

    my $exe = $0;
    # webserver
    for ($conf->start_mode) {
        push @status, { name => $_,
         (
           /hypnotoad/ ? _check_pidfile($conf->hypnotoad->pid_file(default => dirname($exe).'/hypnotoad.pid'))
         : /plackup/   ? _check_pidfile($conf->plackup->pidfile) 
           # NB: see http://redmine.lighttpd.net/issues/2137
           # lighttpd's pid files disappear.  Time to switch to nginx?
         : /lighttpd/       ? _check_pidfile($conf->lighttpd->env->lighttpd_pid)
         : ( state => 'error', message => "Status for start_mode $_ is unimplemented." ))};
    }

    # Do a HEAD request if the webserver(s) are ok.
    if ((grep {$_->{state} eq 'ok'} @status)==@status) {
        my $res = Mojo::UserAgent->new->head($conf->url)->res;
        printf qq[%10s : %-10s (%s %s)\n], "url", $conf->url, $res->code || '?', $res->message || '';
    }

    # Database
    if ( $INC{q[Rose/Planter/DB.pm]} ) {
        if ( my $db_class = Rose::Planter::DB->registered_by($app) ) {
            push @status, _check_database($db_class);
        }
    }

    # Send as YAML if requested?
    for (@status) {
        $_->{message} &&= "($_->{message})";;
        $_->{message} ||= "";
        printf "%10s : %-10s %s\n", @$_{qw/name state message/};
    }
}

1;

