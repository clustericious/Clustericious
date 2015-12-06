package Clustericious::Command::daemon;

use strict;
use warnings;
use base qw( Clustericious::Command );
use Mojolicious::Command::daemon;

# ABSTRACT: Clustericious command to stat nginx
# VERSION

=head1 NAME

Clustericious::Command::daemon - Daemon command

=head1 DESCRIPTION

This is a simple wrapper around L<Mojolicious::Command::daemon> to use
the app's configured URL by default.

=head1 SEE ALSO

L<Clustericious>

=cut

sub description { Start application with HTTP and WebSocket server };
sub usage       { Mojolicious::Command::daemon->extract_usage };

sub run
{
  my($self, @args) = @_;
  
  if(my $url = $self->app->config->{url})
  {
    unshift @args, -l => $url;
  }
  
  Mojolicious::Command::daemon::run($self, @args);
}

1;
