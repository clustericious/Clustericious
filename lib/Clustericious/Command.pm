package Clustericious::Command;

use Mojo::Base 'Mojolicious::Command';

our $VERSION = '0.9924_01';

1;

=head1 NAME

Clustericious::Command - Command base class

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


