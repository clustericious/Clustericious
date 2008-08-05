package Log::Log4perl::CommandLine;

use warnings;
use strict;

our $VERSION = '0.01';

use Log::Log4perl qw(get_logger :levels);
use Getopt::Long qw(:config pass_through);

sub import
{
  my ($class, $logconfig) = @_;

  GetOptions
  (
    'logconfig=s' => \$logconfig,
    'logfile=s'   => \my $logfile
  );

  if ($logconfig and -f $logconfig)
  {
    Log::Log4perl->init($logconfig);
  }
  else
  {
    Log::Log4perl->easy_init($ERROR) unless Log::Log4perl->initialized();
  }

  my $log = get_logger('');

  if ($logfile)
  {
    my $file_appender = Log::Log4perl::Appender->new(
                "Log::Log4perl::Appender::File",
                name => 'logfile',
                filename  => $logfile);
    $file_appender->layout(Log::Log4perl::Layout::PatternLayout->new(
                   "%d %m\n"));
    $log->add_appender($file_appender);
  }

  GetOptions(\my %LogLevels,
    qw(debug:s@ info|verbose:s@ warn:s@ error:s@ fatal:s@ off|quiet:s@));

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

 use Log::Log4perl::CommandLine;

 # or

 use Log::Log4perl::CommandLine qw(/my/default/log.conf);

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

 # Complete list of log level options:
 # debug, info (verbose), warn, error, fatal, off (quiet)

=head1 DESCRIPTION

C<Log::Log4perl::CommandLine> parses some command line options,
allowing for simple configuration of Log4perl using the command line,
or easy, temporary overriding of a more complicated Log4perl
configuration from a file.

Any options parsed and understood by this module are stripped from
@ARGV (by C<Getopt::Long>), so they won't interfere with later command
line parsing.

Be very careful with naming of other options though, since this module
takes over a bit of option space.

=head1 AUTHOR

Curt Tilmes, E<lt>ctilmes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Curt Tilmes

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
