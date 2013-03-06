% my $class = shift;
package <%= $class %>;

=head1 NAME

<%= $class %> - Application Class

=head1 SYNOPSIS

<%= $class %>

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use base 'Clustericious::App';
use <%= $class %>::Routes;

our $VERSION = '0.01';

1;
