%% my $class = shift;
package <%%= $class %%>::App;

=head1 NAME

<%%= $class %%>Sched::App -- The application class.

=head1 DESCRIPTION

This inherits from Clustericious::App which inherits
from Mojolicious.

=cut

use strict;
use warnings;

use base 'Clustericious::App';
use <%%= $class %%>::Routes;

our $VERSION = 0.01;

1;
