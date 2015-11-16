use strict;
use warnings;
use Test::More tests => 1;
use Capture::Tiny qw( capture );

my($out,$err) = capture { require Log::Log4perl::CommandLine };
is $err, '', 'no warnings';


