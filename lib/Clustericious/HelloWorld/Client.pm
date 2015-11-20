package Clustericious::HelloWorld::Client;

use strict;
use warnings;
use Clustericious::Client;
use Clustericious::Client::Command;

# ABSTRACT: Clustericious hello world client
# VERSION

route 'welcome' => "GET",  '/';

1;
