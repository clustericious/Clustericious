package Clustericious::Client::Object::DateTime;

use strict;
use warnings;

# ABSTRACT: Clustericious DateTime object
# VERSION

=head1 SYNOPSIS

 my $obj = Clustericious::Client::Object::DateTime->new('2000-01-01');

 returns a DateTime object from the string date/time.  Expects the
 date/time to be in ISO 8601 format.

=head1 DESCRIPTION

A simple wrapper around DateTime::Format::ISO8601 that provides a
new() function that acts like Clustericious::Client::Object wants it
to.

=cut

use DateTime::Format::ISO8601;

=head1 METHODS

=head2 C<new>

 my $obj = Clustericious::Client::Object::DateTime->new('2000-01-01');

=cut

sub new
{
    my $class = shift;
    my ($datetime) = @_;

    DateTime::Format::ISO8601->new->parse_datetime($datetime);
}

1;
