#!/usr/bin/env perl

use strict;
use warnings;

use Test::More qw/no_plan/;
use Clustericious::Config;

my $c = Clustericious::Config->new(\(my $a = <<'EOT'));
---
something : {
      hello : there,
      this : is,
      some : yaml,
      and : this,
      is : another,
      element : bye,
}
four : {
      <%= "score" =%> : and,
      seven : [ "years", "ago" ],
}

EOT

ok defined( $c->something );
is $c->something->hello,   'there', 'yaml key';
is $c->something->element, 'bye',   'yaml key';
is_deeply [ $c->four->seven ], [qw/years ago/], 'array';

1;

