package Clustericious::Command::nginx;

use strict;
use warnings;
use Clustericious::App;
use Clustericious::Config;
use File::Path qw( mkpath );
use base 'Clustericious::Command';
use Clustericious::Log;
use File::Which qw( which );

# ABSTRACT: Clustericious command to stat nginx
# VERSION

=head1 NAME

Clustericious::Command::nginx - Clustericious command to stat nginx

=head1 DESCRIPTION

Start an nginx web server.

=head1 EXAMPLES

=head2 nginx proxy

# EXAMPLE: example/etc/nginx.conf

=head1 SEE ALSO

L<Clustericious>

=cut

__PACKAGE__->attr(description => <<EOT);
Start an nginx web server.
EOT

__PACKAGE__->attr(usage => <<EOT);
Usage $0: nginx -p <prefix> [...other nginx options]
Starts an nginx webserver.
Options are passed verbatim to the nginx executable.
EOT

sub run {
  my($self, @args) = @_;
  my $app_name = $ENV{MOJO_APP};
  my %args = @args;

  Clustericious::App->init_logging;

  my $prefix = $args{-p} or INFO "no prefix for nginx";
  mkpath "$prefix/logs";

  my $nginx = which('nginx') or LOGDIE "could not find nginx in $ENV{PATH}";
  DEBUG "starting $nginx @args";
  system$nginx, @args;
  die "'$nginx @args' Failed to execute: $!" if $? == -1;
  die "'$nginx @args' Killed with signal: ", $? & 127 if $? & 127;
  die "'$nginx @args' Exited with ", $? >> 8 if $? >> 8;
}

1;

