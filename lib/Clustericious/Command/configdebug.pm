package Clustericious::Command::configdebug;
 
use strict;
use warnings;
use v5.10;
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
print the various stages of the clustericious app configuration file
EOT

has usage => <<EOT;
usage $0: configdebug
print the various stages of the clustericious app configuration file
EOT

sub run
{
  my $self = shift;
  my $app_name = $_[0] || ref($self->app);

  $ENV{MOJO_TEMPLATE_DEBUG} = 1;
  $ENV{CLUSTERICIOUS_CONFIG_SAVE_RENDERED} = 1;

  my $callback1 = sub
  {
    my($class, $src) = @_;
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
  };

  my $callback2 = sub
  {
    my($class, $file, $content) = @_;
    say "[$file :: interpreted]";
    chomp $content;
    say $content;
  };

  # place the hooks in Clustericious::Config which usually
  # doesn't do this debugging stuff.
  do { no warnings; *Clustericious::Config::pre_rendered = $callback1; };
  do { no warnings; *Clustericious::Config::rendered     = $callback2; };

  my $config = Clustericious::Config->new($app_name);

  say "[merged]";
  print Dump({ %$config });

};

1;
