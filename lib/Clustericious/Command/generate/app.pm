package Clustericious::Command::generate::app;

use strict;
use warnings;
use Mojo::Base 'Clustericious::Command';
use File::Find;
use File::Slurp 'slurp';
use File::ShareDir 'dist_dir';
use File::Basename qw/basename/;

# ABSTRACT: Clustericious command to generate a new Clustericious application
our $VERSION = '0.9938'; # VERSION


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
    -x $file && $self->chmod_file($relpath, 0744);
}

sub run
{
    my ($self, $class, @args ) = @_;
    $class ||= 'MyClustericiousApp';
    if (@args % 2) {
        die "usage : $0 generate app <name> --schema <schema>.sql\n";
    }
    my %args = @args;

    my $templatedir = dist_dir('Clustericious') . "/AppTemplate";

    die "Can't find template.\n" unless -d $templatedir;

    find({wanted => sub { $self->_installfile($templatedir, $_, $class) if -f },
          no_chdir => 1}, $templatedir);

}

1;

__END__
=pod

=head1 NAME

Clustericious::Command::generate::app - Clustericious command to generate a new Clustericious application

=head1 VERSION

version 0.9938

=head1 SYNOPSIS

 % clustericious generate app Myapp

=head1 DESCRIPTION

This command generates a new Clustericious application with the given name.

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

