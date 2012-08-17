% my $class = shift;
package <%= $class %>::Client;

use strict;
use warnings;

use Clustericious::Client;

our $VERSION = '0.01';

route 'welcome'   => 'GET', '/';

1;

__END__

=head1 NAME

<%= $class %>::Client - $class Client

=cut

1;

