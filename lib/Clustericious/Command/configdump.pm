package Clustericious::Command::configdump;
 
use strict;
use warnings;
use 5.010001;
use Mojo::Base 'Clustericious::Command';
use Clustericious::Config;
use YAML::XS qw( Dump );

# ABSTRACT: Dump a clustericious configuration
# VERSION

=head1 SYNOPSIS

Given a L<YourApp> clustericious L<Clustericious::App> and C<yourapp> starter script:

 % yourapp configdump

or

 % clustericious configdump YourApp

=head1 DESCRIPTION

This command prints out the post-processed configuration in L<YAML> format.

=head1 SEE ALSO

L<Clustericious::Config>,
L<Clustericious>

=cut

has description => <<EOT;
Dump clustericious configuration
EOT

has usage => <<EOT;
usage $0: configdump [ app ]
EOT

sub run
{
  my($self, $name) = @_;
  my $app_name = $name // ref($self->app);

  my $config = eval {
    Clustericious::Config->new($app_name, sub {
      my($type, $name) = @_;
      if($type eq 'not_found')
      {
        say STDERR "ERROR: unable to find $name";
        exit 2;
      }
    })
  };
  
  if(my $error = $@)
  {
    say STDERR "ERROR: in syntax: $error";
    exit 2;
  }
  else
  {
    print Dump({ %$config });
  }
};

1;
