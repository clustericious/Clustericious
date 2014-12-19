#!/usr/bin/env perl

use strict;
use warnings;

use Test::More qw/no_plan/;
use File::Temp qw/tempdir/;
use Clustericious::Config;

my $dir = tempdir( CLEANUP => 1 );
$ENV{CLUSTERICIOUS_CONF_DIR} = $dir;

#
# Make a common config file called common.conf
#

open my $fh, '>', "$dir/common.conf";
print $fh <<'EOT';
{
   "override_me" : 9,
   "url"        : "<%= $url %>",
   "daemon_prefork" : {
      "listen"   : "<%= $url %>",
      "pid"      : "/tmp/<%= $app %>.pid"
   }
}
EOT
$fh->close;

#
# Make a special config file called special.conf
#

open $fh, '>', "$dir/special.conf";
print $fh <<'EOT';
{
   "specialvalue"  : 123,
   "override_me"   : 10
}
EOT
$fh->close;


#
# Make another config file that references the first one,
# and also has a_remote_app, which has no config file.
#

my $c = Clustericious::Config->new(\(my $a = <<'EOT'));
% extends_config 'common', url => 'http://localhost:9999', app => 'my_app';
% extends_config 'special';
{
   "override_me" : 11,
   "start_mode" : "daemon_prefork",
   "daemon_prefork" : {
      "lock"     : "/tmp/my_app.lock",
      "maxspare" : 2,
      "start"    : 2
   }
}
EOT

#
# Some actual tests.
#
is $c->url, 'http://localhost:9999', 'url is ok';
is $c->{url}, 'http://localhost:9999', 'url is ok';
is $c->url, 'http://localhost:9999', 'url is ok (still)';
is $c->daemon_prefork->listen, $c->url, "extends_config plugin";
is $c->daemon_prefork->listen, "http://localhost:9999", "nested config var again";
my %h = $c->daemon_prefork;
my %i = ( 'listen' => 'http://localhost:9999',
           'pid' => '/tmp/my_app.pid',
           'lock' => '/tmp/my_app.lock',
           'maxspare' => 2,
           'start' => 2
         );
is_deeply \%h, \%i, "got as a hash";
is $c->specialvalue, 123, "read from another conf file";
is $c->override_me, 11, "override a config variable";

is ( (Clustericious::Config->new("SomeTestService")->flooble(default => "frog")), 'frog', 'set a default');
is ( (Clustericious::Config->new("SomeTestService")->flooble), 'frog', 'get a default');

1;

