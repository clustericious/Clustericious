package Clustericious::Command::configure;

use strict;
use warnings;
use 5.010;
use Mojo::Base 'Clustericious::Command';
use Path::Class qw/dir/;

# ABSTRACT: Generate a default configuration.
# VERSION

=head1 SYNOPSIS

Your app:

 package YourApp;
 
 use Mojo::Base qw( Clustericious::App );
 
 sub generate_config
 {
   my ($self, @args) = @_;

   return {
        dirs => [
            ['etc'],
            ['var', 'run' ]
        ],
        files => { 'YourApp.conf' => <<<CUT }
 ---
 required_key   : default_value
 something_else : <%= home %>
 CUT
   };
 }
 
 1;

=head1 DESCRIPTION

Create a default configuration for an app.

=head1 SEE ALSO

L<Clustericious>

=cut

has description => <<EOT;
Write default configuration files.
EOT

has usage => <<EOT;
usage $0: configure
EOT

sub run
{
  my $self = shift;
  my @args = @_ ? @_ : @ARGV;

  my $root = dir($ENV{CLUSTERICIOUS_CONF_DIR} || $ENV{HOME});
  my $conf = $self->app->generate_config(@args);

  for my $d (@{$conf->{dirs} || []}) {
      my $dir = dir($root, @$d);
      -d $dir and do { say "-> exists : $dir"; next; };
      my @made = $dir->mkpath;
      say "-> mkdir $_" for @made;
  }
  
  my $config_root = dir($root)->subdir('etc');
  for my $filename (keys %{$conf->{files}}) {
      my $file = $config_root->file($filename);
      -e $file and do {
          say "-> exists : $file";
          next;
      };
      say "-> write $file";
      $file->spew($conf->{files}{$filename});
  }

  1;
}

1;
