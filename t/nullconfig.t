use strict;
use warnings;
BEGIN { eval 'use EV' }
use Test::More;
BEGIN {
  delete $ENV{HARNESS_ACTIVE};
  plan skip_all => 'test requires Test::Clustericious::Config' unless eval q{ use Test::Clustericious::Config; 1 };
}
plan tests => 1;

eval q{
  package MyApp;
  
  use strict;
  use warnings;
  use Mojo::Base qw( Clustericious::App );
  our $VERSION = '1.00';

  sub startup {
  };

  1;
  
};
die $@ if $@;

my $app = eval { MyApp->new };
isa_ok $app, 'Clustericious::App';
