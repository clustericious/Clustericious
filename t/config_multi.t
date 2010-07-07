#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;
use Clustericious::Config;

my $confa = Clustericious::Config->new(\(my $a = <<'EOT'));
{
   "a" : "valuea",
   "b" : "valueb"
}
EOT

my $confb = Clustericious::Config->new(\(my $b = <<'EOT'));
{
   "a" : "valuea"
}
EOT

is $confa->a, 'valuea';
is $confa->b, 'valueb';

eval { $confa->missing };
like $@, qr/'missing' not found/;

eval { $confb->missing };
like $@, qr/'missing' not found/;

eval { $confb->b };
like $@, qr/'b' not found/;
