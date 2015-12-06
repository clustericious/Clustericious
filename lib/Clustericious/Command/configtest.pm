package Clustericious::Command::configtest;

use strict;
use warnings;
use 5.010;
use Mojo::Base 'Clustericious::Command';

# ABSTRACT: Test a Clustericious application's configuration
# VERSION

=head1 SYNOPSIS

Your app:

 package YourApp;
 
 use Mojo::Base qw( Clustericious::App );
 
 sub sanity_check
 {
   my($self) = @_;
   # ... return true if sane, return false otherwise
   unless($self->config->foo(default => '') eq 'bar')
   {
     say 'your config should set foo to bar';
     return 0;
   }
   
   return 1;
 }
 
 1;

do a sanity check of the configuration:
 
 % yourapp configtest

=head1 DESCRIPTION

This command does a basic sanity check on the configuration for your Clustericious
application, and calls the application's C<sanity_check>

=head1 SEE ALSO

L<Clustericious>

=cut

has description => <<EOT;
Load configuration and test for errors
EOT

has usage => <<EOT;
usage $0: configtest
Load configuration and test for errors
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

