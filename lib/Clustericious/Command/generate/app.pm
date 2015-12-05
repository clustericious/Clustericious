package Clustericious::Command::generate::app;

use strict;
use warnings;
use Clustericious;
use Mojo::Base 'Clustericious::Command';
use File::Find;

# ABSTRACT: Clustericious command to generate a new Clustericious application
# VERSION

=head1 SYNOPSIS

 % clustericious generate app Myapp

=head1 DESCRIPTION

This command generates a new Clustericious application with the given name.

=head1 SEE ALSO

L<Clustericious>

=cut

has description => <<'EOF';
Generate Clustericious app.
EOF

has usage => <<"EOF";
usage: $0 generate app [NAME]
EOF

sub _installfile
{
  my $self = shift;
  my ($templatedir, $file, $class) = @_;

  my $name = lc $class;

  (my $relpath = $file) =~ s/^$templatedir/$class/;
  $relpath =~ s/APPCLASS/$class/g;
  $relpath =~ s/APPNAME/$name/g;

  return if -e $relpath;

  my $content = Mojo::Template->new->render_file( $file, $class );
  $self->write_file($relpath, $content );
  -x $file && $self->chmod_file($relpath, 0755);
}

sub run
{
  my ($self, $class, @args ) = @_;
  $class ||= 'MyClustericiousApp';
  if (@args % 2) {
    die "usage : $0 generate app <name>\n";
  }
  my %args = @args;

  my $templatedir = Clustericious->_dist_dir->subdir('tmpl', '1.08', 'app');

  die "Can't find template.\n" unless -d $templatedir;

  find({wanted => sub { $self->_installfile($templatedir, $_, $class) if -f },
        no_chdir => 1}, $templatedir);
}

1;
