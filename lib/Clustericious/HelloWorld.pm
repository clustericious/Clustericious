package Clustericious::HelloWorld;

use Mojo::Base 'Clustericious::App';
use Clustericious::RouteBuilder qw/Clustericious::HelloWorld/;
use Scalar::Util qw/weaken/;

has commands => sub {
  my $commands = Clustericious::Commands->new(app => shift);
    weaken $commands->{app};
    return $commands;
};

any '/*foo' => {foo => '', text => 'Clustericious is working!'};

1;

