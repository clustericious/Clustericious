% my $class = shift;
#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Mojo;

use_ok('<%= $class %>');

my $t = Test::Mojo->new('<%= $class %>');

$t->get_ok('/')->status_is(200)->content_type_like(qr[text/html])
  ->content_like(qr/welcome/i);

1;

