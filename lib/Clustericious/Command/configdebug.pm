package Clustericious::Command::configdebug;
 
use strict;
use warnings;
use 5.010001;
use Mojo::Base 'Clustericious::Command';
use Clustericious::Config;
use YAML::XS qw( Dump );

# ABSTRACT: Debug a clustericious configuration file
# VERSION

=head1 SYNOPSIS

Given a L<YourApp> clustericious L<Clustericious::App> and C<yourapp> starter script:

 % yourapp configdebug

or

 % clustericious configdebug YourApp

=head1 DESCRIPTION

This command prints out:

=over 4

=item

The pre-processed template configuration for each configuration file used by your application.

=item

The post-processed template configuration for each configuration file used by your application.

=item

The final merged configuration

=back

=head1 SEE ALSO

L<Clustericious::Config>,
L<Clustericious>

=cut

has description => <<EOT;
Print the various stages of the clustericious app configuration file
EOT

has usage => <<EOT;
usage $0: configdebug
Print the various stages of the clustericious app configuration file
EOT

sub run
{
  my $self = shift;
  my $app_name = $_[0] || ref($self->app);

  $ENV{MOJO_TEMPLATE_DEBUG} = 1;

  my $config = Clustericious::Config->new($app_name, sub {
    my $type = shift;
    
    if($type eq 'pre_rendered')
    {
      my($src) = @_;
      my $data;
      if(ref $src)
      {
        say "[SCALAR :: template]";
        $data = $$src;
      }
      else
      {
        say "[$src :: template]";
        open my $fh, '<', $src;
        local $/;
        $data = <$fh>;
        close $fh;
      }
      chomp $data;
      say $data;
    }
    elsif($type eq 'rendered')
    {
      my($file, $content) = @_;
      say "[$file :: interpreted]";
      chomp $content;
      say $content;
    }
  });

  say "[merged]";
  print Dump({ %$config });

};

1;
