package Clustericious::Plugin::AutodataHandler::YAML;

use strict;
use warnings;
use YAML::XS ();
use 5.010;

# ABSTRACT: YAML encoder for AutodataHandler
# VERSION

sub coder
{
  my %coder = (
    type   => 'text/x-yaml',
    format => 'yml',
    encode => sub { YAML::XS::Dump($_[0]) },
    decode => sub { YAML::XS::Load($_[0]) },
  );
  
  \%coder;
}

1;
