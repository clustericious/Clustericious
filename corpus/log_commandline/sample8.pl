use Log::Log4perl qw(:easy);
use Log::Log4perl::CommandLine { layout => '[%-5p] %c %m%n' };

use SampleModule;
use SampleModule2;

SampleModule::test();
SampleModule2::test();

DEBUG "debug message";
INFO  "info  message";
WARN  "warn  message";
ERROR "error message";
FATAL "fatal message";
