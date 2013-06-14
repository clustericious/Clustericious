=head1 NAME

Clustericious::Command::start - Clustericious command to start a Clustericious application

=head1 SYNOPSIS

In your MyApp.conf:

 ---
 start_mode: hypnotoad
 hypnotoad:
   pid: /tmp/restmd.pid
   [...]
   env:
     foo: bar

Then on the command line

 % myapp start

Which is equivalent to

 % foo=bar myapp hypnotoad --pid /tmp/restmd.pid [..]

=head1 DESCRIPTION

Start a daemon using the config file and the start_mode.
 
Keys and values in the configuration file become
options preceded by double dashes.

If a key has a single dash, it is sent as is (with no double dash).

The special value "null" means don't send an argument to the
command line option.

The special label "env" is an optional hash of environment variables
to set before starting the command.

=head1 SUPER CLASS

L<Clustericious::Command>

=head1 SEE ALSO

L<Clustericious>,
L<Clustericious::Command::hypnotoad>

=cut

package Clustericious::Command::start;
use Clustericious::Log;
use File::Slurp qw/slurp/;
use List::MoreUtils qw/mesh/;
use File::Path qw/mkpath/;
use File::Basename qw/dirname/;

use Clustericious::App;
use Clustericious::Config;
use Mojo::Base 'Clustericious::Command';

use strict;
use warnings;

our $VERSION = '0.9924_05';

has description => <<EOT;
Start a daemon using the config file.
EOT

has usage => <<EOT;
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
        if (my $autogen = delete $conf{autogen}) {
            $autogen = [ $autogen ] if ref $autogen eq 'HASH';
            for my $i (@$autogen) {
                DEBUG "autowriting ".$i->{filename};
                mkpath dirname($i->{filename});
                open my $fp, ">$i->{filename}" or LOGDIE "cannot write to $i->{filename} : $!";
                print $fp $i->{content};
                close $fp or LOGDIE $!;
            }
        }

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

