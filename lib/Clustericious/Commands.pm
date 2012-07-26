package Clustericious::Commands;

use strict;
use warnings;

use Clustericious::Config;

use Mojo::Base 'Mojolicious::Commands';

has namespaces => sub { [qw/Clustericious::Command
                           Mojolicious::Command
                           Mojo::Command/] };

1;
