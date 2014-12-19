use strict;
use warnings;
use Test::More tests => 9;
use File::HomeDir::Test;
use File::HomeDir;
use Clustericious::Config;

delete $ENV{CLUSTERICIOUS_CONF_DIR};

mkdir(File::HomeDir->my_home . '/etc');

do {
  my $fh;
  open($fh, '>', File::HomeDir->my_home . '/etc/Foo.conf');
  print $fh "---\n";
  print $fh "test1: 1\n";
  print $fh "% our \$bar;\n";
  print $fh "% \$bar++;\n";
  print $fh "test2: <%= \$bar %>\n";
  close $fh;
};

do {
  my $config = Clustericious::Config->new('Foo');
  isa_ok $config, 'Clustericious::Config';
  is $config->test1, 1, 'test1 = 1';
  is $config->test2, 1, 'test2 = 1';
};

do {
  my $fh;
  open($fh, '>', File::HomeDir->my_home . '/etc/Baz.conf');
  print $fh "---\n";
  print $fh "test1: 1\n";
  print $fh "% our \$bar;\n";
  print $fh "% \$bar++;\n";
  print $fh "test2: <%= \$bar %>\n";
  close $fh;
};

do {
  my $config = Clustericious::Config->new('Baz');
  isa_ok $config, 'Clustericious::Config';
  is $config->test1, 1, 'test1 = 1';
  is $config->test2, 1, 'test2 = 1';
};

do {
  my $fh;
  open($fh, '>', File::HomeDir->my_home . '/etc/Flag.conf');
  print $fh "---\n";
  print $fh "<%= extends_config 'Baz' %>\n";
  close $fh;
};

do {
  my $config = Clustericious::Config->new('Flag');
  isa_ok $config, 'Clustericious::Config';
  is $config->test1, 1, 'test1 = 1';
  is $config->test2, 1, 'test2 = 1';
};

