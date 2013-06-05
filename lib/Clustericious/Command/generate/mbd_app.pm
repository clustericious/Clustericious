package Clustericious::Command::generate::mbd_app;

use strict;
use warnings;

use Mojo::Base 'Clustericious::Command';

use File::Find;
use File::Slurp 'slurp';
use File::ShareDir 'dist_dir';
use File::Basename qw/basename/;

=head1 NAME

Clustericious::Command::generate::mbd_app - Clustericious command to generate a new Clustericious M::B::D application

=head1 SYNOPSIS

 % clustericious generate mbd_app Myapp --schema schema.sql

=head1 DESCRIPTION

This command generates a new Clustericious Module::Build::Database application with the given name and schema.

=head1 SUPER CLASS

L<Clustericious::Command>

=head1 SEE ALSO

L<Clustericious>

=cut


our $VERSION = '0.9923';

has description => <<'EOF';
Generate Clustericious app based on Module::Build::Database.
EOF

has usage => <<"EOF";
usage: $0 generate mbd_app [NAME]
EOF

sub get_data
{
    my ($self, $data, $class) = @_;

    return slurp($data);
}

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
    -x $file && $self->chmod_file($relpath, 0744);
}

sub run
{
    my ($self, $class, @args ) = @_;
    $class ||= 'MyClustericiousApp';
    if (@args % 2) {
        die "usage : $0 generate mbd_app <name> --schema <schema>.sql\n";
    }
    my %args = @args;

    my $templatedir = dist_dir('Clustericious') . "/MbdAppTemplate";

    die "Can't find template.\n" unless -d $templatedir;

    find({wanted => sub { $self->_installfile($templatedir, $_, $class) if -f },
          no_chdir => 1}, $templatedir);

    if (my $schema = $args{'--schema'}) {
        my $content = slurp $schema;
        my $base = basename $schema;
        $self->write_file("$class/db/patches/0020_$base", $content);
    }
}

1;
