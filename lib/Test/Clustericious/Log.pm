package Test::Clustericious::Log;

use strict;
use warnings;
use v5.10;

BEGIN {
  unless($INC{'File/HomeDir/Test.pm'})
  {
    eval q{ use File::HomeDir::Test };
    die $@ if $@;
  }
}

use File::HomeDir;
use Test::Builder::Module;
use Clustericious::Log ();
use Carp qw( carp );

# ABSTRACT: Clustericious logging in tests.
# VERSION

=head1 SYNOPSIS

 use Test::Clustericious::Log;
 use Test::More;
 use MyClustericiousApp;
 
 my $app = MyClustericiousApp->new;
 
 ok $test, 'test description';
 ...

=head1 DESCRIPTION

This module redirects the log4perl output from a 
L<Clustericious> application to TAP using 
L<Test::Builder>.  By default it sends DEBUG to WARN messages
to C<note> and ERROR to FATAL to C<diag>, so you should only
see error and fatal messages if you run C<prove -l> on your test
but will see debug and warn messages if you run C<prove -lv>.

If the test fails for any reason, the entire log file will be
printed out using C<diag> when the test is complete.  This
is useful for CPAN testers reports.

=cut

# TRACE DEBUG INFO WARN ERROR FATAL

sub import
{
  my($class) = shift;

  # first caller wins
  state $counter = 0;
  if($counter++)
  {
    my $caller = caller;
    unless($caller eq 'Test::Clustericious::Cluster')
    {
      my $tb = Test::Builder::Module->builder;
      $tb->diag("you must use Test::Clustericious::Log before Test::Clustericious::Cluster");
    }
    return;
  }

  $Clustericious::Log::harness_active = 0;

  my $home = File::HomeDir->my_home;
  mkdir "$home/etc" unless -d "$home/etc";
  mkdir "$home/log" unless -d "$home/log";

  my $config = {
    FileX => [ 'TRACE', 'FATAL'  ],
    NoteX => [ 'DEBUG', 'WARN'  ],
    DiagX => [ 'ERROR', 'FATAL' ],
  };

  my $args;
  if(@_ == 1)
  {
    die;
  }
  else
  {
    $args = { @_ };
  }
  
  foreach my $type (qw( file note diag ))
  {
    if(defined $args->{$type})
    {
      my $name = ucfirst($type) . 'X';
      if($args->{$type} =~ /^(TRACE|DEBUG|INFO|WARN|ERROR|FATAL)(..(TRACE|DEBUG|INFO|WARN|ERROR|FATAL))$/)
      {
        my($min,$max) = ($1,$3);
        $max = $min unless $max;
        $config->{$name} = [ $min, $max ];
      }
      elsif($args->{$type} eq 'NONE')
      {
        delete $config->{$name};
      }
      else
      {
        carp "illegal log range: " . $args->{$type};
      }
    }
  }
  
  open my $fh, '>', "$home/etc/log4perl.conf";

  print $fh "log4perl.rootLogger=TRACE, ";
  print $fh "FileX, " if defined $config->{FileX};
  print $fh "NoteX, " if defined $config->{NoteX};
  print $fh "DiagX, " if defined $config->{DiagX};
  print $fh "\n";
  
  while(my($appender, $levels) = each %$config)
  {
    my($min, $max) = @{ $levels };
    print $fh "log4perl.filter.Match$appender = Log::Log4perl::Filter::LevelRange\n";
    print $fh "log4perl.filter.Match$appender.LevelMin = $min\n";
    print $fh "log4perl.filter.Match$appender.LevelMax = $max\n";
    print $fh "log4perl.filter.Match$appender.AcceptOnMatch = true\n";
  }
  
  print $fh "log4perl.appender.FileX=Log::Log4perl::Appender::File\n";
  print $fh "log4perl.appender.FileX.filename=$home/log/test.log\n";
  print $fh "log4perl.appender.FileX.mode=append\n";
  print $fh "log4perl.appender.FileX.layout=PatternLayout\n";
  print $fh "log4perl.appender.FileX.layout.ConversionPattern=[%P %p{1} %rms] %F:%L %m%n\n";
  print $fh "log4perl.appender.FileX.Filter=MatchFileX\n";
  
  print $fh "log4perl.appender.NoteX=Log::Log4perl::Appender::TAP\n";
  print $fh "log4perl.appender.NoteX.method=note\n";
  print $fh "log4perl.appender.NoteX.layout=PatternLayout\n";
  print $fh "log4perl.appender.NoteX.layout.ConversionPattern=%5p %m%n\n";
  print $fh "log4perl.appender.NoteX.Filter=MatchNoteX\n";

  print $fh "log4perl.appender.DiagX=Log::Log4perl::Appender::TAP\n";
  print $fh "log4perl.appender.DiagX.method=diag\n";
  print $fh "log4perl.appender.DiagX.layout=PatternLayout\n";
  print $fh "log4perl.appender.DiagX.layout.ConversionPattern=%5p %m%n\n";
  print $fh "log4perl.appender.DiagX.Filter=MatchDiagX\n";
  
  close $fh;  
}

END
{
  my $tb = Test::Builder::Module->builder;
  my $home = File::HomeDir->my_home;
  
  unless($tb->is_passing)
  {
    if(-r "$home/log/test.log")
    {
      $tb->diag("detailed log");
      open my $fh, '<', "$home/log/test.log";
      $tb->diag(<$fh>);
      close $fh;
    }
    else
    {
      $tb->diag("no detailed log");
    }
  }
}

1;
