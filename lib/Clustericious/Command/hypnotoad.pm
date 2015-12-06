package Clustericious::Command::hypnotoad;

use strict;
use warnings;
use Clustericious;
use Clustericious::App;
use Clustericious::Log;
use Mojo::Server::Hypnotoad;
use base 'Clustericious::Command';

# ABSTRACT: Clustericious command to stat Hypnotoad
# VERSION

=head1 DESCRIPTION

Start a hypnotoad web server.

Configuration for the server is taken directly from the
"hypnotoad" entry in the config file, and turned into
a config file for hypnotoad.  Among other options in
this section these are recognized:

=over 4

=item listen

List of URLS to listen on

=item pid_file

The location of the PID file.  For the stop command to
work this MUST be specified.,

=back

=head1 EXAMPLES

=head2 hypnotoad by itself

Create a hypnotoad.conf:

# EXAMPLE: example/etc/hypnotoad.conf

Then call from your application's config file:

 ---
 % extend_config 'hypnotoad', host => 'localhost', port => 3001;

=head2 paired with another server

Examples for proxying another server to a hypnotoad back end
can be found in L<Clustericious::Command::apache> and
L<Clustericious::Command::nginx>.

=head1 SEE ALSO

L<Clustericious>
L<Mojo::Server::Hypnotoad>,

=cut

__PACKAGE__->attr(description => "Start a hypnotad web server.\n");

__PACKAGE__->attr(usage => <<EOT);
Usage $0: hypnotoad
No options are available.  The 'hypnotoad' entry in the config file
is used for configuration.
EOT

sub run {
  my($self, @args) = @_;
  my $conf = $self->app->config->hypnotoad;
  my $exe = $0;
  DEBUG "Running hypnotoad : $exe";
  $ENV{HYPNOTOAD_EXE} = "$0";
  my $sentinel = '/no/such/file/because/these/are/deprecated';
  if ( $ENV{HYPNOTOAD_CONFIG} && $ENV{HYPNOTOAD_CONFIG} ne $sentinel ) {
    WARN "HYPNOTOAD_CONFIG value $ENV{HYPNOTOAD_CONFIG} will be ignored";
  }
  # During deprecation, this value must be defined but not pass the -r test
  # to avoid warnings.
  my $pid = fork();
  if (!defined($pid)) {
    LOGDIE "Unable to fork";
  }

  unless ($pid) {
    DEBUG "Child process $$";
    local $ENV{HYPNOTOAD_CONFIG} = $sentinel;
    my $pid_file = $conf->{pid_file};
    if (-e $pid_file) {
      chomp (my $pid = Clustericious::_slurp_pid $pid_file);
      if (!kill 0, $pid) {
        WARN "removing old pid file $pid_file";
        unlink $pid_file or WARN "Could not remove $pid_file : $!";
      }
    }
    my $toad = Mojo::Server::Hypnotoad->new;
    $ENV{CLUSTERICIOUS_COMMAND_NAME} = 'hypnotoad';
    $toad->run($exe);
    WARN "hypnotoad exited";
    exit;
  }
  # TODO: see if we can get away without
  # using this sleep... it would speed up
  # the test suite a lot.
  sleep 1;
  return 1;
}

1;

