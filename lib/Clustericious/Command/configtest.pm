package Clustericious::Command::configtest;

use strict;
use warnings;
use v5.10;
use Mojo::Base 'Clustericious::Command';

our $VERSION = '0.9928';

has description => <<EOT;
load configuration and test for errors
EOT

has usage => <<EOT;
usage $0: configtest
load configuration and test for errors
EOT

sub run
{
  my $self = shift;
  my @args = @_ ? @_ : @ARGV;
  
  my $app = $self->app;
  
  exit 2 unless $app->sanity_check;
  
  say 'config okay';
}

1;

