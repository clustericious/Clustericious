#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Mojo;

use_ok('Clustericious');
use_ok('Clustericious::Node');
use_ok('Clustericious::RouteBuilder');

1;

