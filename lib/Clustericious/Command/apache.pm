package Clustericious::Command::apache;

use strict;
use warnings;
use Clustericious::App;
use base 'Clustericious::Command';
use File::Which qw( which );

# ABSTRACT: Clustericious command to stat Apache
# VERSION

=head1 DESCRIPTION

Start an Apache web server.  The Apache start and stop commands recognize these options
in their configuration section:

=over 4

=item pid_file

The location to the pid file.  This should usually be the same as the C<PidFile> directive
in your Apache configuration.

=back

=head1 EXAMPLES

These examples are for Apache 2.4.  Getting them to work on Apache
2.2 will require some tweaking.

=head2 mod_proxy with hypnotoad

Create a apache24-proxy.conf:

# EXAMPLE: example/etc/apache24-proxy.conf

Note that this configuration binds hypnotoad to C<localhost> and
Apache to the IP that you pass in.  Then call from your application's
config file:

 ---
 # If hostname() (should be the same as what the command hostname
 # prints) is not a valid address that you can bind to, or if 
 # your hostname is the IP as localhost, then change the host to
 # a literal IP address
 % extend_config 'apache24-proxy', host => hostname(), port => 3001;

=head2 CGI

CGI is not recommends, for reasons that are hopefully obvious.  It does
allow you to run Clustericious from 

Create a apache24-cgi.conf:

# EXAMPLE: example/etc/apache24-cgi.conf

Then call from your application's config file:

 ---
 % extend_config 'apache24-cgi', host => 'localhost', port => 3001;

=head1 SEE ALSO

L<Clustericious>

=cut

__PACKAGE__->attr(description => <<EOT);
Start an Apache web server.
EOT

__PACKAGE__->attr(usage => <<EOT);
Usage $0: Apache -f <conf> [...other Apache options]
Starts an Apache webserver.
Options are passed verbatim to the httpd executable.
EOT

sub run {
  my($self, @args) = @_;
  Clustericious::App->init_logging;
  my $command = which('httpd') || die "unable to find apache";
  system $command, @args;
  die "'$command @args' Failed to execute: $!" if $? == -1;
  die "'$command @args' Killed with signal: ", $? & 127 if $? & 127;
  die "'$command @args' Exited with ", $? >> 8 if $? >> 8;
}

1;

