package Clustericious::Command::plackup;

use strict;
use warnings;
use Clustericious::Log;
use Clustericious::App;
use Mojo::Server::PSGI;
use base 'Clustericious::Command';
use File::Which qw( which );
use Mojo::URL;

# ABSTRACT: Clustericious command to start plack server
# VERSION

=head1 SYNOPSIS

 % yourapp plackup

=head1 DESCRIPTION

Start a plack server using plackup.  By default plackup does not daemonize into the
background, making it a handy development server.  Any arguments will be passed into
the plackup command directly.

=head1 SEE ALSO

L<Clustericious>, L<plackup>, L<Plack>

=cut

__PACKAGE__->attr(description => <<EOT);
Start a plack server (see plackup)
EOT

__PACKAGE__->attr(usage => <<EOT);
Usage $0: plackup [plackup options]
Starts a plack server.  See plackup for valid options.
EOT

sub run {
  my($self) = shift;
  my @args = @_ ? @_ : @ARGV;
  my $app_name = $ENV{MOJO_APP};
  
  Clustericious::App->init_logging;

  my $plackup = which('plackup') || LOGDIE "could not find plackup in $ENV{PATH}";

  my $url = Mojo::URL->new($self->app->config->url);
  LOGDIE "@{[ $url->scheme ]} not supported" if $url->scheme ne 'http';
  
  shift @args if $args[0] eq 'plackup';
  push @args, $0;
  unshift @args, '--port' => $url->port;
  unshift @args, '--host' => $url->host;
  
  #if(my $pid_file = $self->app->config->plackup(default => {})->pid_file(default => 0))
  #{
  #  unshift @args, '--pidfile' => $pid_file;
  #}
  
  DEBUG "starting $plackup @args";
  delete $ENV{MOJO_COMMANDS_DONE};
  print "PID = $$\n";
  exec $plackup, @args;
}

1;

