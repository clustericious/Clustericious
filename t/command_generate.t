use strict;
use warnings;
use autodie;
use Test::Clustericious::Command;
use Test::More tests => 1;
use File::Temp qw( tempdir );
use File::chdir;

mirror 'bin', 'bin';

subtest app => sub {

  local $CWD = tempdir( CLEANUP => 1 );
  note "% cd $CWD";
  
  run_ok('clustericious', 'generate', 'app', 'Foo')
    ->exit_is(0)
    ->note;
  
  $CWD = 'Foo';
  note "% cd $CWD"; 
  
  run_ok($^X, 'Build.PL')
    ->exit_is(0)
    ->note;

  run_ok('./Build')
    ->exit_is(0)
    ->note;

  run_ok('./Build', 'test')
    ->exit_is(0)
    ->note;

};
