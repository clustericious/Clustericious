use strict;
use warnings;
use Test::More tests => 2;
use Clustericious::Config;
use File::Temp qw( tempdir );
use File::Spec;
use YAML::XS qw( DumpFile );

foreach my $ext (qw( conf yml ))
{

  subtest "with .$ext" => sub {
  
    my $filename = File::Spec->catfile( tempdir( CLEANUP => 1 ), "Foo.$ext");
    DumpFile($filename, { a => 1, b => 2 });
    ok -r $filename, "created $filename";
    
    my $config = Clustericious::Config->new($filename);
    isa_ok $config, 'Clustericious::Config';
    
    is $config->a, 1, 'config.a = 1';
    is $config->b, 2, 'config.b = 2';
  };

}


