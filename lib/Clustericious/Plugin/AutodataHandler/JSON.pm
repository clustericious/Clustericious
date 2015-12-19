package Clustericious::Plugin::AutodataHandler::JSON;

use strict;
use warnings;
use JSON::MaybeXS ();
use 5.010;

# ABSTRACT: JSON encoder for AutodataHandler
# VERSION

sub coder
{
  my $json = JSON::MaybeXS->new
    ->allow_nonref
    ->allow_blessed
    ->convert_blessed;

  my %coder = (
    type   => 'application/json',
    format => 'json',
    encode => sub { $json->encode($_[0]) },
    decode => sub { $json->decode($_[0]) },
  );
  
  \%coder;
}

1;
