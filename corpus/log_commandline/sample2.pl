use Log::Log4perl qw(:easy);
use Log::Log4perl::CommandLine;

use SampleModule;

SampleModule::test();

DEBUG "debug message";
INFO  "info  message";
WARN  "warn  message";
ERROR "error message";
FATAL "fatal message";
