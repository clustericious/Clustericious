use strict;
use warnings;
use Test::Clustericious::Config;
use Test::More;
BEGIN {
  plan skip_all => 'test requires Path::Class'
    unless eval q{ use Path::Class qw( file dir ); 1 };
};
plan tests => 5;

my $nested_file = file(home_directory_ok, qw( foo bar baz here.txt ));
$nested_file->parent->mkpath(0,0700);
$nested_file->spew('hi there');

create_config_ok Foo => <<EOF;
---
test_dir: <%= dir home, qw( foo bar baz ) %>
test_file: <%= file home, qw( foo bar baz here.txt ) %>
conf_file: <%= __FILE__ %>
conf_line: <%= __LINE__ %>
EOF

my $config = eval { Clustericious::Config->new('Foo') };
diag $@ if $@;
isa_ok $config, 'Clustericious::Config';

my $dir = eval { $config->test_dir };
diag $@ if $@;
ok $dir && -d $dir, "dir = $dir";

my $file = eval { $config->test_file };
diag $@ if $@;
ok $file && -f $file, "file = $file";

note "conf_file: " . $config->conf_file;
note "conf_line: " . $config->conf_line;
