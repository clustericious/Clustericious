package Clustericious::HelloWorld;

use Mojo::Base 'Clustericious::App';
use Clustericious::RouteBuilder qw/Clustericious::HelloWorld/;

our $VERSION = '0.9920';

BEGIN {
    $ENV{LOG_LEVEL} = 'FATAL';
}

any '/*foo' => {foo => '', text => 'Clustericious is working!'};

1;

