use strict;
use warnings;
use Clustericious::Config::Plugin;
use Clustericious::Config::Helpers;
use Test::More tests => 1;

push @Clustericious::Config::Plugin::EXPORT, 'foo';
ok scalar(grep /^foo$/, @Clustericious::Config::Helpers::EXPORT), "::Plugin::EXPORT is linked to ::Helper::EXPORT";
