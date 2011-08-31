package Clustericious::Command::Generate::MbdApp;

use strict;
use warnings;

use base 'Mojo::Command';

use File::Find;
use File::Slurp 'slurp';
use File::ShareDir 'dist_dir';
  
__PACKAGE__->attr(description => <<'EOF');
Generate Clustericious app based on Module::Build::Database.
EOF
__PACKAGE__->attr(usage => <<"EOF");
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

    $self->render_to_rel_file($file, $relpath, $class) unless -e $relpath;
}

sub run
{
    my ($self, $class) = @_;
    $class ||= 'MyClustericiousApp';

    my $templatedir = dist_dir('Clustericious') . "/MbdAppTemplate";

    die "Can't find template.\n" unless -d $templatedir;

    $self->renderer->line_start('%%');
    $self->renderer->tag_start('<%%');
    $self->renderer->tag_end('%%>');

    find({wanted => sub { $self->_installfile($templatedir, $_, $class) if -f },
          no_chdir => 1}, $templatedir);
}

1;
