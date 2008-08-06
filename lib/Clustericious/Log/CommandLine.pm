package Log::Log4perl::CommandLine;

use warnings;
use strict;

our $VERSION = '0.02';

use Log::Log4perl qw(get_logger :levels);
use Getopt::Long qw(:config pass_through);

my $Init;
my $LogConfig;
my $LogFile;
my %LogLevels;

sub import
{
  my $class = shift;
  $Init = shift;
}

BEGIN
{
  GetOptions
  (
    'logconfig=s' => \$LogConfig,
    'logfile=s'   => \$LogFile
  );

  GetOptions(\%LogLevels,
    qw(debug:s@ info|verbose:s@ warn:s@ error:s@ fatal:s@ off|quiet:s@));
}

INIT
{
  init($LogConfig ? $LogConfig : $Init);
}

sub init
{
  my ($init) = @_;

  if (defined $init and (ref($init) eq 'SCALAR' or -f $init))
  {
    Log::Log4perl->init($init);
  }
  elsif (not Log::Log4perl->initialized)
  {
    $init = {} unless ref($init) eq 'HASH';

    $init->{level}  ||= $ERROR;
    $init->{layout} ||= '[%-5p] %m%n';

    Log::Log4perl->easy_init($init);
  }

  my $log = get_logger('');

  if ($LogFile)
  {
    my $layout = '%d %c %m%n';

    if ($LogFile =~ s/\|(.*)$//)
    {
      $layout = $1;
    }

    my $file_appender = Log::Log4perl::Appender->new(
                "Log::Log4perl::Appender::File",
                name => 'logfile',
                filename  => $LogFile);

    $file_appender->layout(Log::Log4perl::Layout::PatternLayout->new(
                 $layout));

    $log->add_appender($file_appender);
  }

  while (my ($level, $vals) = each %LogLevels)
  {
    my $level_id = Log::Log4perl::Level::to_priority(uc $level);

    @$vals = split(',', join(',', @$vals));
    if (@$vals)
    {
      foreach my $category (@$vals)
      {
        get_logger($category)->level($level_id);
      }
    }
    else
    {
      $log->level($level_id);
    }
  }
}

1;

__END__

=head1 NAME

Log::Log4perl::CommandLine - Simple Command Line Interface for Log4perl

=head1 SYNOPSIS

 use Log::Log4perl qw(:easy); # to get constants

 # Some alternatives:

 use Log::Log4perl::CommandLine;
 use Log::Log4perl::CommandLine { level => $INFO };
 use Log::Log4perl::CommandLine { layout => '%d %c %m%n' };
 use Log::Log4perl::CommandLine { level => $WARN, layout => '%d %c %m%n' };
 use Log::Log4perl::CommandLine qw(/my/default/log.conf);
 use Log::Log4perl::CommandLine \q(...some log4perl config...);

 # These configure the root logger:

 my_program.pl --verbose                # sets root logger to INFO
 my_program.pl -v                       # sets root logger to INFO
 my_program.pl --debug                  # sets root logger to DEBUG
 my_program.pl -d                       # sets root logger to DEBUG
 my_program.pl --quiet                  # sets root logger to OFF
 my_program.pl -q                       # sets root logger to OFF

 # Or you can configure a specific category:

 my_program.pl --verbose Some::Module
 my_program.pl --debug Broken::Module

 # You can have multiple options, or separate by commas:

 my_program.pl --verbose Module1 --verbose Module2
 my_program.pl --verbose Module1,Module2

 # Simple changes to log configuration:

 my_program.pl --logconfig /another/log.conf  # Command line override

 my_program.pl --logfile /path/log.txt        # Add a simple file logger

 my_program.pl --logfile "log.file|%d %m%n"   # Optional layout override

 # Complete list of log level options:
 # debug, info (verbose), warn, error, fatal, off (quiet)

=head1 DESCRIPTION

C<Log::Log4perl::CommandLine> parses some command line options,
allowing for simple configuration of Log4perl using the command line,
or easy, temporary overriding of a more complicated Log4perl
configuration from a file.

The <use Log::Log4perl> line is needed if you want to use the
constants ($ERROR, $INFO, etc.) or what to use Log4perl logging in
your program (which you should).  If a main program doesn't use
Log4perl, but uses modules that do, you can just add one line C<use
Log::Log4perl::CommandLine;> and everything will just work.

Any options parsed and understood by this module are stripped from
@ARGV (by C<Getopt::Long>), so they won't interfere with later command
line parsing.

Be very careful with naming of other options though, since this module
takes over a bit of option space.

=head1 BUGS

Experimental for comments, interface may change.

=head1 AUTHOR

Curt Tilmes, E<lt>ctilmes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Curt Tilmes

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
