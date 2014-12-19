#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 6;
use Clustericious::Config;

my $confa = Clustericious::Config->new(\(my $a = <<'EOT'));
{
   "a" : "valuea",
   "b" : "valueb",
   "c" : {
        "x" : "y"
         }
}
EOT

my $confb = Clustericious::Config->new(\(my $b = <<'EOT'));
{
   "a" : "valuea"
}
EOT

is $confa->a, 'valuea', "value a set";
is $confa->b, 'valueb', "value b set";

do {

  no warnings 'redefine';
  local *Carp::cluck = sub { };

  eval { $confa->missing };
  like $@, qr/'missing' not found/, "missing a value";

  eval { $confb->missing };
  like $@, qr/'missing' not found/, "missing a value";

  eval { $confb->b };
  like $@, qr/'b' not found/, "no autovivivication in other classes";

};

is $confb->c(default => ''), '', "no autovivication in other classes";

1;
