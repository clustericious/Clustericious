package Clustericious::Command::Generate;

use strict;
use warnings;

use base 'Mojolicious::Command::generate';

__PACKAGE__->attr(namespaces =>
      sub { [qw/Clustericious::Command::Generate
                Mojolicious::Command::Generate
                Mojolicious::Command::Generate/] });

1;
