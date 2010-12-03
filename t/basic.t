#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Mojo;

use IO::Prompt; # silence warning about CHECK block
use_ok('Clustericious');
use_ok('Clustericious::App');
use_ok('Clustericious::RouteBuilder', "TestAppClass");

1;

