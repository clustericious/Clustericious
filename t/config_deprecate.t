use strict;
use warnings;
use Test::Clustericious::Config;
use Clustericious::Config;
use Clustericious::Config::Helpers;
use Test::More tests => 3;
use Test::Warn;

subtest 'old Test::Clustericious::Cluster' => sub {
  plan tests => 3;

  warning_is(
    sub { require_ok 'Clustericious::Config::Plugin' }, 
    'Clustericious::Config::Plugin is deprecated and will be removed on or after January 31 2016', 
    'deprecation warning',
  );

  push @Clustericious::Config::Plugin::EXPORT, 'foo';
  ok scalar(grep /^foo$/, @Clustericious::Config::Helpers::EXPORT), "::Plugin::EXPORT is linked to ::Helper::EXPORT";

};

subtest 'string scalar' => sub {
  plan tests => 4;

  my $config;

  warning_is(
    sub { $config = Clustericious::Config->new( \"---\na: 1\nb: 2\n" ) }, 
    'string scalar configuration is deprecated', 
    'deprecation warning',
  );

  isa_ok $config, 'Clustericious::Config';
  is $config->a, 1, 'config.a';
  is $config->b, 2, 'config.a';

};

subtest 'json config' => sub {

  create_config_ok 'Json' => '{ "c":1, "d":2 }';

  my $config;
  
  warning_is(
    sub { $config = Clustericious::Config->new('Json') },
    'JSON configuration file is deprecated',
    'deprecation warnings',
  );
  
  isa_ok $config, 'Clustericious::Config';
  is $config->c, 1, 'config.c';
  is $config->d, 2, 'config.d';

};
