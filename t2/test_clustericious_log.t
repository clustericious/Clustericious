use Test2::Bundle::Extended;
use Test::Clustericious::Log import => ':all';
use Clustericious::Log -init_logging => "Froodle";
use YAML::XS qw( Load );

subtest exports => sub {

  imported_ok $_ for qw(
    log_events
    log_context
    log_like
    log_unlike
  );
  
};

subtest log_events => sub {

  my @e = log_context {
    TRACE "main trace";
    DEBUG "main debug";
    INFO  "main info";
    WARN  "main warn";
    ERROR "main error";
    FATAL "main fatal";
    log_events;
  };

  my $expected = Load(<<EOF);
---
- level: 0
  log4p_category: main
  log4p_level: TRACE
  message: main trace
  name: TestX
- level: 0
  log4p_category: main
  log4p_level: DEBUG
  message: main debug
  name: TestX
- level: 1
  log4p_category: main
  log4p_level: INFO
  message: main info
  name: TestX
- level: 3
  log4p_category: main
  log4p_level: WARN
  message: main warn
  name: TestX
- level: 4
  log4p_category: main
  log4p_level: ERROR
  message: main error
  name: TestX
- level: 7
  log4p_category: main
  log4p_level: FATAL
  message: main fatal
  name: TestX
EOF

  is(\@e, $expected, 'log_events');

};

done_testing;
