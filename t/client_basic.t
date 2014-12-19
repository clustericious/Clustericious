#!/usr/bin/env perl

use strict;
use warnings;
BEGIN { eval q{ use EV } }

use Test::More tests => 1;

use_ok('Clustericious::Client');
