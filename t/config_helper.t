use strict;
use warnings;
use Test::More tests => 3;
use Test::Clustericious::Config;

my $counter = 1;
create_config_helper_ok foo => sub { $counter++ };
create_config_ok Bar => <<EOF;
---
one: <%= foo %>
two: <%= foo %>
three: <%= foo %>
EOF

is(Clustericious::Config->new('Bar')->two, 2, "two = 2");
