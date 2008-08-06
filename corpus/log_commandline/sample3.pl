use Log::Log4perl qw(:easy);
use Log::Log4perl::CommandLine { level => $INFO };

DEBUG "debug message";
INFO  "info  message";
WARN  "warn  message";
ERROR "error message";
FATAL "fatal message";
