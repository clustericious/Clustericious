#!/usr/bin/env perl

use strict;
use warnings;

use Test::More qw/no_plan/;
use Clustericious::Config;

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
   "services" : [

%# Uses "a_local_app.conf" for key-value pairs.
      { "name" : "a_local_app" },

%# Local values override anything in "a_remote_app.conf".
      { "name" : "a_remote_app",
        "url"  : "http://localhost:9191"
      }
   ]
}
EOT

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

1;

