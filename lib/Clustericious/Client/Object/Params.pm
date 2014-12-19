package Clustericious::Client::Object::Params;

use strict;
use warnings;
use base 'Clustericious::Client::Object';

# ABSTRACT: object parameters
# VERSION

=head1 SYNOPSIS

 my $data = 
 [
     { name => 'foo', value => 'foovalue' },
     { name => 'bar', value => 'barvalue' }
 ];

 my $obj = Clustericious::Client::Object::Params->new($data);

 $obj->{foo} -> 'foovalue';
 $obj->{bar} -> 'barvalue';

=head1 DESCRIPTION

Takes an array reference of hashes with 'name' and 'value' keys and
transforms it into a single flattened hash of name => value.

=head1 METHODS

=head2 C<new>

 my $obj = Clustericious::Client::Object::Params->new($data);

=cut

sub new
{
    my $class = shift;
    my ($paramlist) = @_;

    $class->SUPER::new({ map { $_->{name} => $_->{value} } @$paramlist });
}

1;
