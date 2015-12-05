package Test::Clustericious::Command;

use strict;
use warnings;
use 5.010;
use if !$INC{'File/HomeDir/Test.pm'}, 'File::HomeDir::Test';
use base qw( Exporter Test::Builder::Module );
use Exporter qw( import );
use Mojo::Loader;
use Path::Class qw( file dir );
use File::HomeDir;
use Env qw( @PERL5LIB @PATH );
use Capture::Tiny qw( capture );
use File::Which qw( which );
use Mojo::Template;

# ABSTRACT: Test Clustericious commands
# VERSION

=head1 SYNOPSIS

 use Test::Clustericious::Command;

=head1 DESCRIPTION

Documentation to be added later.

=cut

our @EXPORT      = qw( extract_data mirror requires run_ok generate_port );
our @EXPORT_OK   = @EXPORT;
our %EXPORT_TAGS = ( all => \@EXPORT );

unshift @INC, dir(File::HomeDir->my_home, 'lib')->stringify;
unshift @PERL5LIB, @INC;
unshift @PATH, dir(File::HomeDir->my_home, 'bin')->stringify;

=head1 FUNCTIONS

=head2 requires

=cut

sub requires
{
  my($command, $num) = @_;
  my $tb = __PACKAGE__->builder;
  if(which $command)
  {
    if(defined $num)
    {
      $tb->plan( tests => $num );
    }
  }
  else
  {
    $tb->plan( skip_all => "test requires $command to be in the PATH" );
  }
}

=head2 extract_data

=cut

sub extract_data
{
  my(@values) = @_;
  my $caller = caller;
  Mojo::Loader::load_class $caller;
  my $all = Mojo::Loader::data_section $caller;
  
  my $tb = __PACKAGE__->builder;
  
  foreach my $name (sort keys %$all)
  {
    my $file = file(File::HomeDir->my_home, $name);
    my $dir  = $file->parent;
    unless(-d $dir)
    {
      $tb->note("[extract] DIR  $dir");
      $dir->mkpath(0,0700);
    }
    unless(-f $file)
    {
      $tb->note("[extract] FILE $file@{[ $name =~ m{^bin/} ? ' (*)' : '']}");
      
      if($name =~ m{^bin/})
      {
        my $content = $all->{$name};
        $content =~ s{^#!/usr/bin/perl}{#!$^X};
        $file->spew($content);
        chmod 0700, "$file";
      }
      elsif($name =~ m{^etc/})
      {
        my $content = $all->{$name};
        my $mt = Mojo::Template->new(
          tag_start => '[%',
          tag_end   => '%]',
          line_start => '^',
        );
        $file->spew($mt->render($content, @values));
      }
      else
      {
        $file->spew($all->{$name});
      }
    }
  }
}

=head2 mirror

=cut

sub mirror
{
  my($src, $dst) = map { ref ? $_ : dir($_) } @_;
  
  my $tb = __PACKAGE__->builder;

  $dst = dir(File::HomeDir->my_home, $dst) unless $dst->is_absolute;
  
  unless(-d $dst)
  {
    $tb->note("[mirror ] DIR  $dst");
    $dst->mlpath(0,0700);
  }
  
  foreach my $child ($src->children)
  {
    if($child->is_dir)
    {
      mirror($child, $dst->subdir($child->basename));
    }
    else
    {
      my $dst = $dst->file($child->basename);
      unless(-f $dst)
      {
        $tb->note("[mirror ] FILE $dst@{[ -x $child ? ' (*)' : '' ]}");
        $dst->spew(scalar $child->slurp);
        -x $child ? chmod 0700, "$dst" : chmod 0600, "$dst";
      }
    }
  }
}

=head2 run_ok

=cut

sub run_ok
{
  my(@cmd) = @_;
  my($out, $err, $ret, $error, $exit) = capture { my $ret = system @cmd; ($ret,$!,$?) };
  
  my $ok = $ret == 0 && ! ($? & 128);
  
  my $tb = __PACKAGE__->builder;
  
  $tb->ok($ok, "@cmd");
  $tb->diag("  @cmd failed") unless $ok;
  $tb->diag("    - execute failed: $error") if $ret;
  $tb->diag("    - died from signal: " . ($exit & 128)) if $exit & 128;
  
  bless { out => $out, err => $err, exit => $exit >> 8 }, 'Test::Clustericious::Command::Run';
}

=head2 generate_port

=cut

sub generate_port
{
  require IO::Socket::INET;
  IO::Socket::INET->new(Listen => 5, LocalAddr => "127.0.0.1")->sockport;
}

package Test::Clustericious::Command::Run;

use base qw( Test::Builder::Module );

sub out { shift->{out} }
sub err { shift->{err} }
sub exit { shift->{exit} }

sub exit_is
{
  my($self, $value, $name) = @_;
  $name //= "exit with $value";
  my $tb = __PACKAGE__->builder;
  $tb->is_eq($self->exit, $value, $name);
  $self;
}

sub note
{
  my($self) = @_;
  my $tb = __PACKAGE__->builder;
  $tb->note("[out]\n" . $self->out) if $self->out;
  $tb->note("[err]\n" . $self->err) if $self->err;
  $self;
}

1;
