package Clustericious::Config::Helpers;

use strict;
use warnings;
use v5.10;
use Hash::Merge qw/merge/;
use Data::Dumper;
use Carp qw( croak );
use base qw( Exporter );
use JSON::XS qw( encode_json );

# ABSTRACT: Helpers for clustericious config files.
our $VERSION = '0.9940_01'; # VERSION


our @mergeStack;
our @EXPORT = qw( extends_config get_password home file dir hostname hostname_full json yaml );


sub extends_config {
    my $filename = shift;
    my @args = @_;
    push @mergeStack, Clustericious::Config->new($filename, \@args);
    return '';
}

#
#
# do_merges:
#
# Called after reading all config files, to process extends_config
# directives.
#
sub _do_merges {
    my $class = shift;
    my $conf_data = shift; # Last one; Has highest precedence.

    return $conf_data unless @mergeStack;

    # Nested extends_config's form a tree which we traverse depth first.
    Hash::Merge::set_behavior( 'RIGHT_PRECEDENT' );
    my %so_far = %{ shift @mergeStack };
    while (my $c = shift @mergeStack) {
        my %h = %$c;
        %so_far = %{ merge( \%so_far, \%h ) };
    }
    %$conf_data = %{ merge( \%so_far, $conf_data ) };
}


sub get_password {
    return Clustericious::Config::Password->sentinel;
}


sub home (;$)
{
  require File::HomeDir;
  $_[0] ? File::HomeDir->users_home($_[0]) : File::HomeDir->my_home;
}


sub file
{
  eval { require Path::Class::File };
  croak "file helper requires Path::Class" if $@;
  Path::Class::File->new(@_);
}


sub dir
{
  require Path::Class::Dir;
  croak "dir helper requires Path::Class" if $@;
  Path::Class::Dir->new(@_);
}


sub hostname
{
  state $hostname;
  
  unless(defined $hostname)
  {
    require Sys::Hostname;
    $hostname = Sys::Hostname::hostname();
    $hostname =~ s/\..*$//;
  }
  
  $hostname;
}


sub hostname_full
{
  require Sys::Hostname;
  Sys::Hostname::hostname();
}


sub json ($)
{
  encode_json($_[0]);
}


sub yaml ($)
{
  require YAML::XS;
  local $YAML::UseHeader = 0;
  my $str = YAML::XS::Dump($_[0]);
  $str =~ s{^---\n}{};
  $str;
}


1;

__END__
=pod

=head1 NAME

Clustericious::Config::Helpers - Helpers for clustericious config files.

=head1 VERSION

version 0.9940_01

=head1 SYNOPSIS

 ---
 % extend_config 'SomeOtherConfig';

=head1 DESCRIPTION

This module provides the functions available in all configuration files
using L<Clustericious::Config>.

=head1 FUNCTIONS

=head2 extends_config $config_name, %arguments

Extend the config using another config file.

=head2 get_password

Prompt for a password.  This will prompt the user the first time it is
encountered for a password.

=head2 home( [ $user ] )

Return the given users' home directory, or if no user is
specified return the calling user's home directory.

=head2 file( @list )

The C<file> shortcut from Path::Class, if it is installed.

=head2 dir( @list )

The C<dir> shortcut from Path::Class, if it is installed.

=head2 hostname

The system hostname (uses L<Sys::Hostname>)

=head2 hostname_full

The system hostname in full, including the domain, if
it can be determined (uses L<Sys::Hostname>).

=head2 json $ref

Encode the given hash or list reference.

=head2 yaml $ref

Encode the given hash or list reference.

=head1 SEE ALSO

L<Clustericious::Config>, L<Clustericious>

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

