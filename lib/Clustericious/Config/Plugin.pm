package Clustericious::Config::Plugin;

use strict;
use warnings;
use Clustericious::Config::Helpers;
use Carp ();

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

Carp::carp "Clustericious::Config::Plugin is deprecated and will be removed on or after January 31 2016";

if(scalar caller eq 'Test::Clustericious::Cluster')
{
  Carp::carp "Upgrade your version of Test::Clustericious::Cluster, otherwise it will stop working when Clustericious::Config::Plugin is removed";
}


1;
