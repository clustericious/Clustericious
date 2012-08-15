package Clustericious::HelloWorld;

use Mojo::Base 'Clustericious::App';
use Clustericious::RouteBuilder qw/Clustericious::HelloWorld/;

any '/*foo' => {foo => '', text => 'Clustericious is working!'};

1;

