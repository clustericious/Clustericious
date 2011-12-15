package Clustericious::JSON;
use Math::BigInt;

use base 'JSON::XS';

sub new {
    my $json = shift->SUPER::new(@_);
    $json->allow_blessed;
    $json->convert_blessed;
    return $json;
}

sub Math::BigInt::TO_JSON {
    my $val = shift;
    return "$val";
}


1;

