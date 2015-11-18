package Clustericious::Command;

use strict;
use warnings;
use Mojo::Base 'Mojolicious::Command';

# ABSTRACT: Command base class
# VERSION

=head1 SYNOPSIS

 use Mojo::Base 'Mojolicious::Command';

=head1 DESCRIPTION

This class is the base class for all Clustericious commands.  It
inherits everything from L<Mojolicious::Command> and will may add
Clustericious specific behavior in the future.

=head1 COMMANDS

This is a (not exhaustive) list of common Clustericious commands:

=over 4

=item *

L<hypnotoad|Clustericious::Command::hypnotoad>

=item *

L<start|Clustericious::Command::start>

=item *

L<stop|Clustericious::Command::stop>

=item *

L<status|Clustericious::Command::status>

=item *

L<generate app|Clustericious::Command::generate::app>

=item *

L<generate client|Clustericious::Command::generate::client>

=item *

L<generate mbd_app|Clustericious::Command::generate::mbd_app>

=back

=head1 SUPER CLASS

L<Mojolicious::Command>
 
=head1 SEE ALSO

L<Clustericious>
L<Mojolicious::Command>

=cut

1;
