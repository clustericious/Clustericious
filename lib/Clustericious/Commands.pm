package Clustericious::Commands;

use strict;
use warnings;

use Clustericious::Config;

use base 'Mojolicious::Commands';

__PACKAGE__->attr(namespaces => sub { [qw/Clustericious::Command
                                          Mojolicious::Command
                                          Mojo::Command/] });

1;
