use strict;
use warnings;
use autodie;
use Clustericious;
use Test::Clustericious::Command;
use Test::More;
use File::Temp qw( tempdir );
use Path::Class qw( dir );
use File::chdir;
use File::Which qw( which );

$ENV{PERL_FILE_SHAREDIR_DIST} = 'Clustericious=' . Clustericious->_dist_dir;

note "share directory = ", Clustericious->_dist_dir;

requires undef, 2;
mirror 'bin', 'bin';
extract_data;

my $have_prove = eval q{ use App::Prove; 1 };
my $have_yath  = eval q{ use App::Yath;  1 };

foreach my $type (qw( app client ))
{
  subtest $type => sub {
    plan tests => 14;
  
    local $CWD = tempdir( CLEANUP => 1 );
    note "% cd $CWD";
  
    run_ok('clustericious', 'generate', $type, 'Foo')
      ->exit_is(0)
      ->note;
  
    ($CWD) = dir->children;
    note "% cd $CWD"; 
  
    SKIP: {
      skip 'Test requires prove', 2 unless $have_prove;
      skip 'Test requires yath executable', 2 unless !! which('prove');
      run_ok('prove', '-l')
        ->exit_is(0)
        ->note;
    }
    
    SKIP: {
      skip 'Test requires yath', 2 unless $have_yath;
      skip 'Test requires yath executable', 2 unless !! which('yath');
      run_ok('yath')
        ->exit_is(0)
        ->note;
    };

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

__DATA__

@@ bin/prove
#!/usr/bin/perl
use strict;
use warnings;
use App::Prove;
my $app = App::Prove->new;
$app->process_args(@ARGV);
$app->run;

@@ bin/yath
#!/usr/bin/yath
use strict;
use warnings;
use App::Yath (\@ARGV, \$App::Yath::RUN);
exit($App::Yath::RUN->());
