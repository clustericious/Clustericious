package Clustericious::Command::configure;

use strict;
use warnings;
use v5.10;
use Mojo::Base 'Clustericious::Command';
use Path::Class qw/dir/;

# ABSTRACT: Generate a default configuration.
our $VERSION = '0.9930'; # VERSION


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


__END__
=pod

=head1 NAME

Clustericious::Command::configure - Generate a default configuration.

=head1 VERSION

version 0.9930

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
 something_else : <%= $ENV{HOME} %>
 CUT
   };
 }
 
 1;

=head1 DESCRIPTION

Create a default configuration for an app.

=head1 SUPER CLASS

L<Clustericious::Command>

=head1 SEE ALSO

L<Clustericious>

=head1 AUTHOR

original author: Brian Duggan

current maintainer: Graham Ollis <plicease@cpan.org>

contributors:

Curt Tilmes

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

