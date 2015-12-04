package Clustericious::Command::apache;

use strict;
use warnings;
use Clustericious::App;
use Clustericious::Config;
use File::Path qw/mkpath/;
use base 'Clustericious::Command';
use Clustericious::Log;
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

=head2 mod_proxy with hypnotoad

Create a apache-proxy.conf:

# EXAMPLE: example/etc/apache-proxy.conf

Note that this configuration binds hypnotoad to C<localhost> and
Apache to the IP that you pass in.  Then call from your application's
config file:

 ---
 # If hostname() (should be the same as what the command hostname
 # prints) is not a valid address that you can bind to, or if 
 # your hostname is the IP as localhost, then change the host to
 # a literal IP address
 % extend_config 'apache-proxy', host => hostname(), port => 3001;

=head2 CGI

CGI is not recommends, for reasons that are hopefully obvious.  It does
allow you to run Clustericious from 

Create a apache-cgi.conf:

# EXAMPLE: example/etc/apache-cgi.conf

Then call from your application's config file:

 ---
 % extend_config 'apache-cgi', host => 'localhost', port => 3001;

=head1 SUPER CLASS

L<Clustericious::Command>

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
    my $self = shift;
    my @args = @_ ? @_ : @ARGV;
    my $app_name = $ENV{MOJO_APP};

    Clustericious::App->init_logging;

    my $apache = which('httpd') || die "unable to find apache";
    system $apache, @args;
    die "'$apache @args' Failed to execute: $!" if $? == -1;
    die "'$apache @args' Killed with signal: ", $? & 127 if $? & 127;
    die "'$apache @args' Exited with ", $? >> 8 if $? >> 8;
}

1;

