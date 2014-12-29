use strict;
use warnings;
use Test::More tests => 4;
use Test::Mojo;

#use IO::Prompt; # silence warning about CHECK block
use_ok('Clustericious');
use_ok('Clustericious::App');
use_ok('Clustericious::RouteBuilder', "TestAppClass");
use_ok('Clustericious::Command::generate');

1;

