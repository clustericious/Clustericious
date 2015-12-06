package Clustericious::Command::lighttpd;

use strict;
use warnings;
use Clustericious::Log;
use Clustericious::App;
use Clustericious::Config;
use base 'Clustericious::Command';
use File::Which qw( which );

# ABSTRACT: Clustericious command to stat lighttpd
# VERSION

=head1 SYNOPSIS

 % yourapp start

=head1 DESCRIPTION

Start a lighttpd web server. The lighttpd start and stop commands recognize these options
in their configuration section:

=over 4

=item pid_file

The location to the pid file.  This should usually be the same as the C<PidFile> directive
in your lighttpd configuration.

=back
 
=head1 EXAMPLES

=head2 FCGI

See caveats below

# EXAMPLE: example/etc/lighttpd.conf

=head1 CAVEATS

I was unable to get lighttpd to kill the FCGI processes and there are reports
(see L<http://redmine.lighttpd.net/issues/2137>) of the PID file it generates
disappearing.  Because of the former limitation, the lighttpd tests for
Clustericious are skipped by default (though they can be used by developers
willing to manually kill the FCGI processes).

Pull requests to Clustericious and / or documentation clarification would be
greatly appreciated if someone manages to get it to work better!

=head1 SEE ALSO

L<Clustericious>

=cut

__PACKAGE__->attr(description => <<EOT);
Start a lighttpd web server.
EOT

__PACKAGE__->attr(usage => <<EOT);
Usage $0: lighttpd -f <config file> [...other lighttpd options]
Starts a lighttpd webserver.
Options are passed verbatim to the lighttpd executable.
EOT

sub run {
  my($self, @args) = @_;
  my $app_name = $ENV{MOJO_APP};

  # Clustericious::App->init_logging;

  my $lighttpd = which('lighttpd') or LOGDIE "could not find lighttpd in $ENV{PATH}";
  DEBUG "starting $lighttpd @args";
  system $lighttpd, @args;
  die "'$lighttpd @args' Failed to execute: $!" if $? == -1;
  die "'$lighttpd @args' Killed with signal: ", $? & 127 if $? & 127;
  die "'$lighttpd @args' Exited with ", $? >> 8 if $? >> 8;
}

1;


