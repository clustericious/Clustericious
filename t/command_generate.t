use strict;
use warnings;
use autodie;
use Test::Clustericious::Command;
use Test::More;
use File::Temp qw( tempdir );
use Path::Class qw( dir );
use File::chdir;
use File::Which qw( which );

requires undef, 3;
mirror 'bin', 'bin';

my $prove = eval q{ use App::prove; 1 };

foreach my $type (qw( app client ))
{
  subtest $type => sub {
    plan tests => 12;
  
    local $CWD = tempdir( CLEANUP => 1 );
    note "% cd $CWD";
  
    run_ok('clustericious', 'generate', $type, 'Foo')
      ->exit_is(0)
      ->note;
  
    ($CWD) = dir->children;
    note "% cd $CWD"; 
  
    SKIP: {
      skip 'Test requires prove', 2 unless $prove;
      run_ok('prove', '-l')
        ->exit_is(0)
        ->note;
    }

    run_ok($^X, 'Build.PL')
      ->exit_is(0)
      ->note;

    run_ok('./Build', 'manifest')
     ->exit_is(0)
     ->note;

    run_ok('./Build')
      ->exit_is(0)
      ->note;

    run_ok('./Build', 'test')
      ->exit_is(0)
      ->note;
    
  };
}

subtest 'mbd_app' => sub {
  plan tests => 3;

  run_ok('clustericious', 'generate', 'mbd_app', 'Foo')
    ->exit_is(2)
    ->err_like(qr{ERROR: this command has been removed});

};

__DATA__

@@ bin/prove
#!/usr/bin/perl
use strict;
use warnings;
use App::Prove;
my $app = App::Prove->new;
$app->process_args(@ARGV);
$app->run;
