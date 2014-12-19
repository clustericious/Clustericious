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
# VERSION

=head1 SYNOPSIS

 ---
 % extend_config 'SomeOtherConfig';

=head1 DESCRIPTION

This module provides the functions available in all configuration files
using L<Clustericious::Config>.

=head1 FUNCTIONS

=cut

our @mergeStack;
our @EXPORT = qw( extends_config get_password home file dir hostname hostname_full json yaml );

=head2 extends_config $config_name, %arguments

Extend the config using another config file.

=cut

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

=head2 get_password

Prompt for a password.  This will prompt the user the first time it is
encountered for a password.

=cut

sub get_password {
    return Clustericious::Config::Password->sentinel;
}

=head2 home( [ $user ] )

Return the given users' home directory, or if no user is
specified return the calling user's home directory.

=cut

sub home (;$)
{
  require File::HomeDir;
  $_[0] ? File::HomeDir->users_home($_[0]) : File::HomeDir->my_home;
}

=head2 file( @list )

The C<file> shortcut from Path::Class, if it is installed.

=cut

sub file
{
  eval { require Path::Class::File };
  croak "file helper requires Path::Class" if $@;
  Path::Class::File->new(@_);
}

=head2 dir( @list )

The C<dir> shortcut from Path::Class, if it is installed.

=cut

sub dir
{
  require Path::Class::Dir;
  croak "dir helper requires Path::Class" if $@;
  Path::Class::Dir->new(@_);
}

=head2 hostname

The system hostname (uses L<Sys::Hostname>)

=cut

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

=head2 hostname_full

The system hostname in full, including the domain, if
it can be determined (uses L<Sys::Hostname>).

=cut

sub hostname_full
{
  require Sys::Hostname;
  Sys::Hostname::hostname();
}

=head2 json $ref

Encode the given hash or list reference.

=cut

sub json ($)
{
  encode_json($_[0]);
}

=head2 yaml $ref

Encode the given hash or list reference.

=cut

sub yaml ($)
{
  require YAML::XS;
  local $YAML::UseHeader = 0;
  my $str = YAML::XS::Dump($_[0]);
  $str =~ s{^---\n}{};
  $str;
}

=head1 SEE ALSO

L<Clustericious::Config>, L<Clustericious>

=cut

1;
