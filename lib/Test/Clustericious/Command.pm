package Test::Clustericious::Command;

use strict;
use warnings;
use 5.010001;
use if !$INC{'File/HomeDir/Test.pm'}, 'File::HomeDir::Test';
use base qw( Exporter Test::Builder::Module );
use Exporter qw( import );
use Mojo::Loader;
use Path::Class qw( file dir );
use File::HomeDir;
use Env qw( @PERL5LIB @PATH );
use Capture::Tiny qw( capture );
use File::Which qw( which );
use File::Glob qw( bsd_glob );
use YAML::XS ();

# ABSTRACT: Test Clustericious commands
# VERSION

=head1 SYNOPSIS

 use Test::Clustericious::Command;

=head1 DESCRIPTION

Documentation to be added later.

=cut

our @EXPORT      = qw( extract_data mirror requires run_ok generate_port note_file clean_file create_symlink );
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

  if($command =~ /^(.*)\.conf$/)
  {
    my $name = $1;
    if(defined $ENV{CLUSTERICIOUS_COMMAND_TEST} && -r $ENV{CLUSTERICIOUS_COMMAND_TEST})
    {
      my $config = YAML::XS::LoadFile($ENV{CLUSTERICIOUS_COMMAND_TEST})->{$name};
      $tb->plan( skip_all => "developer test not configured" ) unless defined $config;
      
      unshift @PATH, $config->{path} if defined $config->{path};
      unshift @PATH, dir(File::HomeDir->my_home, 'bin')->stringify;
      $ENV{$_} = $config->{env}->{$_} for keys %{ $config->{env} };
      $command = $config->{exe} // $name;
    }
    else
    {
      $tb->plan( skip_all => "developer only test" );
    }
  }

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
    $dst->mkpath(0,0700);
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
        if(-x $dst)
        {
          $tb->note("[mirror ] FILE $dst (*)");
          my $content = scalar $child->slurp;
          $content =~ s{^#!/usr/bin/perl}{#!$^X};
          $dst->spew($content);
          chmod 0700, "$dst";
        }
        else
        {
          $tb->note("[mirror ] FILE $dst");
          $dst->spew(scalar $child->slurp);
          chmod 0600, "$dst";
        }
      }
    }
  }
}

=head2 run_ok

=cut

sub run_ok
{
  my(@cmd) = @_;
  my($out, $err, $error, $exit) = capture { system @cmd; ($!,$?) };
  
  my $ok = ($exit != -1) && ! ($exit & 128);
  
  my $tb = __PACKAGE__->builder;
  
  $tb->ok($ok, "@cmd");
  $tb->diag("  @cmd failed") unless $ok;
  $tb->diag("    - execute failed: $error") if $exit == -1;
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

=head2 note_file

=cut

sub note_file
{
  my $tb = __PACKAGE__->builder;

  foreach my $file (sort map { file $_ } map { bsd_glob "~/$_" } @_)
  {
    $tb->note("[content] $file");
    $tb->note(scalar $file->slurp);
  }
}

=head2 clean_file

=cut

sub clean_file
{
  foreach my $file (sort map { file $_ } map { bsd_glob "~/$_" } @_)
  {
    $file->remove;
  }
}

=head2 create_symlink

=cut

sub create_symlink
{
  my $tb = __PACKAGE__->builder;
  my($old,$new) = map { file(File::HomeDir->my_home, $_) } @_;
  $new->remove if -f $new;
  $tb->note("[symlink] $old => $new");
  use autodie;
  symlink "$old", "$new";
  %Clustericious::Config::singletons = ();
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

sub diag
{
  my($self) = @_;
  my $tb = __PACKAGE__->builder;
  $tb->diag("[out]\n" . $self->out) if $self->out;
  $tb->diag("[err]\n" . $self->err) if $self->err;
  $self;
}

sub out_like
{
  my($self, $pattern, $name) = @_;
  my $tb = __PACKAGE__->builder;
  
  $name ||= "output matches";
  $tb->like($self->out, $pattern, $name);

  $self;
}

sub out_unlike
{
  my($self, $pattern, $name) = @_;
  my $tb = __PACKAGE__->builder;
  
  $name ||= "output does not match";
  $tb->unlike($self->out, $pattern, $name);

  $self;
}

sub err_like
{
  my($self, $pattern, $name) = @_;
  my $tb = __PACKAGE__->builder;
  
  $name ||= "error matches";
  $tb->like($self->err, $pattern, $name);

  $self;
}

sub err_unlike
{
  my($self, $pattern, $name) = @_;
  my $tb = __PACKAGE__->builder;
  
  $name ||= "error does not match";
  $tb->unlike($self->err, $pattern, $name);
  
  $self;
}

sub tap
{
  my($self, $sub) = @_;
  $sub->($self);
  $self;
}

1;
