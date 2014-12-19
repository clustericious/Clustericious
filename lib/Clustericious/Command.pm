package Clustericious::Command;

use strict;
use warnings;
use Mojo::Base 'Mojolicious::Command';

# ABSTRACT: Command base class
our $VERSION = '0.9940_01'; # VERSION



1;

__END__
=pod

=head1 NAME

Clustericious::Command - Command base class

=head1 VERSION

version 0.9940_01

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

=head1 AUTHOR

original author: Brian Duggan

current maintainer: Graham Ollis <plicease@cpan.org>

contributors:

Curt Tilmes

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

