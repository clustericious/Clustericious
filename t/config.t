#!/usr/bin/env perl

use strict;
use warnings;

use Test::More qw/no_plan/;
use File::Temp qw/tempdir/;
use Clustericious::Config;
use IO::File;

my $dir = tempdir();
$ENV{CLUSTERICIOUS_TEST_CONF_DIR} = $dir;

#
# Make one config file called a_local_app.conf
#

my $fp = IO::File->new("> $dir/a_local_app.conf");
print $fp <<'EOT';
{
    "url" : "http://localhost:10211"
}
EOT
$fp->close;

#
# Make another config file that references the first one,
# and also has a_remote_app, which has no config file.
#

my $c = Clustericious::Config->new(\(my $a = <<'EOT'));
% my $url = "http://localhost:9999";

{
   "url"        : "<%= $url %>",
   "start_mode" : "daemon_prefork",
   "daemon_prefork" : {
      "listen"   : "<%= $url %>",
      "pid"      : "/tmp/my_app.pid",
      "lock"     : "/tmp/my_app.lock",
      "maxspare" : 2,
      "start"    : 2
   },
   "peers" : [

%# Uses "a_local_app.conf" for key-value pairs.
      "a_local_app",

%# Local values override anything in "a_remote_app.conf".
      { "name" : "a_remote_app",
        "url"  : "http://localhost:9191"
      }
   ]
}
EOT

#
# Some actual tests.
#
is $c->url, 'http://localhost:9999', 'url is ok';
is $c->{url}, 'http://localhost:9999', 'url is ok';
is $c->url, 'http://localhost:9999', 'url is ok (still)';
is $c->daemon_prefork->listen, $c->url, "nested config var";
is $c->daemon_prefork->listen, "http://localhost:9999", "nested config var again";
my %h = $c->daemon_prefork;
my %i = ( 'listen' => 'http://localhost:9999',
           'pid' => '/tmp/my_app.pid',
           'lock' => '/tmp/my_app.lock',
           'maxspare' => 2,
           'start' => 2
         );
is_deeply \%h, \%i, "got as a hash";

is $c->peers->a_remote_app->url, "http://localhost:9191", "remote peer";
is $c->peers->a_local_app->url, "http://localhost:10211", "local peer";

1;

