package Clustericious::Command::morbo;

use strict;
use warnings;
use 5.010001;
use base qw( Clustericious::Command );
use Mojolicious::Command::daemon;
use File::Which qw( which );
use Capture::Tiny qw( capture );

# ABSTRACT: Clustericious command to stat nginx
# VERSION

=head1 NAME

Clustericious::Command::morbo - Run clustericious service with morbo

=head1 DESCRIPTION

This is a simple wrapper around L<morbo> to use
the app's configured URL by default.

=head1 SEE ALSO

L<Clustericious>

=cut

sub description { 'Start application with Morbo server' };
sub usage       {
  state $usage;
  
  unless($usage)
  {
    my $command = which 'morbo';
    die "morbo not found!" unless defined $command;
    my($out, $err) = capture { system $command, '--help' };
    $usage = $err;
  }
  
  $usage;
};

sub run
{
  my($self, @args) = @_;
  
  if(my $url = $self->app->config->{url})
  {
    unshift @args, -l => $url;
  }

  my $command = which 'morbo';
  die "morbo not found!" unless defined $command;

  exec $command, @args, $0;
}

1;
