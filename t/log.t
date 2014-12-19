use strict;
use warnings;
use Test::Clustericious::Log;
use Clustericious::Log -init_logging => "Froodle";
use Test::More tests => 1;

TRACE "trace";
DEBUG "debug";
INFO  "info";
WARN  "warn";
ERROR "error";
FATAL "fatal";

pass 'pass';

