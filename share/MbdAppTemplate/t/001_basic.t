%% my $class = shift;
#!/usr/bin/env perl

use strict;
use warnings;

use Test::MBD '-autostart';
use Test::More tests => 7;
use Test::Mojo;

use_ok('<%%= $class %%>');

my $t = Test::Mojo->new(app => '<%%= $class %%>');

$t->get_ok('/')->status_is(200)->content_type_is('text/html')
  ->content_like(qr/welcome/i);

$t->get_ok('/clustericious/<%%= $class %%>')
  ->json_content_is( { app => "<%%= $class %%>", version => $<%%= $class %%>::VERSION }, "DB version is $<%%= $class %%>::VERSION " );

