package Clustericious::HelloWorld::Client;

use strict;
use warnings;
use Clustericious::Client;
use Clustericious::Client::Command;

route 'welcome' => "GET",  '/';

1;
