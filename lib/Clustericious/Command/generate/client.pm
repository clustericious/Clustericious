package Clustericious::Command::generate::client;

use strict;
use warnings;

use Mojo::Base 'Clustericious::Command';

use File::Find;
use File::Slurp 'slurp';
use File::ShareDir 'dist_dir';
use File::Basename qw/basename/;

=head1 NAME

Clustericious::Command::generate::client - Clustericious command to generate a new Clustericious client

=head1 SYNOPSIS

 % clustericious generate client Myapp

=head1 DESCRIPTION

This command generates a new Clustericious client with the given name.

=head1 SUPER CLASS

L<Clustericious::Command>

=head1 SEE ALSO

L<Clustericious>, L<Clustericious::Client>

=cut

our $VERSION = '0.9926';

has description => <<'EOF';
Generate Clustericious::Client-derived client.
EOF

has usage => <<"EOF";
usage: $0 generate client [SERVER APP NAME]
EOF

sub get_data
{
    my ($self, $data, $class) = @_;

    return slurp($data);
}

sub _installfile
{
    my $self = shift;
    my ($templatedir, $file, $serverclass, $moduledir) = @_;

    my $name = lc $serverclass;

    (my $relpath = $file) =~ s/^$templatedir/$moduledir/;
    $relpath =~ s/APPCLASS/$serverclass/g;
    $relpath =~ s/APPNAME/$name/g;

    return if -e $relpath;

    my $content = Mojo::Template->new->render_file( $file, $serverclass );
    $self->write_file($relpath, $content );
    -x $file && $self->chmod_file($relpath, 0744);
}

sub run
{
    my ($self, $serverclass, @args ) = @_;
    $serverclass ||= 'MyClustericiousApp';
    if (@args % 2) {
        die "usage : $0 generate client <app_name>\n";
    }
    my %args = @args;

    die "app_name should be the server name" if $serverclass =~ /\-/;

    my $moduledir = $serverclass.'-Client';

    my $templatedir = dist_dir('Clustericious') . "/ClientTemplate";

    die "Can't find template in $templatedir.\n" unless -d $templatedir;

    find({wanted => sub { $self->_installfile($templatedir, $_, $serverclass, $moduledir) if -f },
          no_chdir => 1}, $templatedir);

}

1;
