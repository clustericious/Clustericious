use strict;
use warnings;
use Test::More tests => 2;
use Capture::Tiny qw( capture );

do {
  package Clustericious;
  
  $INC{'Clustericious.pm'} = __FILE__;
  
  sub _config_path {
    qw(
      /home/foo/etc
      /home/foo/.dist/perl/Clustericious
      /etc
    )
  }
};

require_ok 'Clustericious::Commands';

my($out,$err) = capture {
  local @ARGV = qw( configpath );
  Clustericious::Commands->start;
};

note "[out]\n$out";

is_deeply [split /\n\r?/, $out], [ qw( /home/foo/etc /home/foo/.dist/perl/Clustericious /etc ) ], 'output';
