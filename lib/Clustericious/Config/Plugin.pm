package Clustericious::Config::Plugin;

use strict;
use warnings;
use Clustericious::Config::Helpers;

# ABSTRACT: Deprecated module
# VERSION

=head1 DESCRIPTION

This is module is deprecated, please see
L<Clustericious::Config::Helper>.

=cut

# Hack to keep old versions of Test::Clustericious::Cluster working
*EXPORT = \@Clustericious::Config::Helpers::EXPORT;

sub Clustericious::Config::Helpers::cluster
{
  goto &Clustericious::Config::Plugin::cluster;
}

1;
