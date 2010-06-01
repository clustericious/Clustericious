%% my $class = shift;
package <%%= $class %%>;

=head1 NAME

<%%= $class %%> - Application Class

=head1 SYNOPSIS

<%%= $class %%>

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use base '<%%= $class %%>::App';

our $VERSION = '0.01';

# This package is basically just an alias for <%%= $class %%>::App.

1;
