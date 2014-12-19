use strict;
use warnings;
use Test::Clustericious::Config;
use Test::More tests => 1;

create_config_ok 'Foo';

__DATA__

@@ etc/Foo.conf
---
a: 1
b: 2
