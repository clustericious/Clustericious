package Clustericious::Command::which;

use strict;
use warnings;
use 5.010;
use Sub::Identify 0.05 qw( get_code_location get_code_info );
use Mojo::Base qw( Clustericious::Command );

# ABSTRACT: Clustericious command to start a Clustericious application
# VERSION 

has description => <<EOT;
Determine the location of method or helper.
EOT

has usage => <<EOT;
usage $0: which method
EOT

sub run
{
  my($self, $method) = @_;
  my $app = $self->app;
  my $controller = $app->build_controller;
  
  unless($method)
  {
    say STDERR "no method specified";
    exit 1;
  }
  
  my $type;
  my $sub;
  
  if($sub = $controller->can($method))
  {
    $type = "controller method";
  }
  elsif($sub = $app->renderer->get_helper($method))
  {
    $type = "helper";
  }
  elsif($sub = $app->can($method))
  {
    $type = "app method";
  }
  else
  {
    say STDERR "No such method or helper: $method";
    exit 2;
  }

  my($class, $name) = get_code_info     $sub;
  my($file,  $line) = get_code_location $sub;
  
  say "type:     $type";
  say "class:    $class";
  say "name:     $name" if $name ne '__ANON__';
  say "location: $file:$line";
}

1;
