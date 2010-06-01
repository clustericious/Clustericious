%% my $class = shift;
%% my $name = lc $class;
%% my $upname = uc $class;
=head1 NAME

<%%= $class %%>::DB -- Manage the database connection.

=head1 DESCRIPTION

This is derived from Rose::DB, with our connection parameters.

There are three potential sets of connection parameters.

1. test -- used when the test suite is running, connects to a host set within the test suite.

2. dev -- uses the environment variable PGHOST to determine the database host.

3. live -- uses the environment variable PGHOST to determine the database host.

Currently the only distinction between 2 and 3 is that 3 is chosen when the
environment variable <%%= $upname %%>_LIVE is set to true.

All three make use of a database named <%%= $name %%>server, and schema named <%%= $name %%>schema.

=cut

package <%%= $class %%>::DB;
use base "Rose::DB";
use strict;
use warnings;

# TODO get database + schema from Build.pl somehow (via config?)

__PACKAGE__->register_db(
    domain   => "test",
    type     => "main",
    driver   => "Pg",
    database => "<%%= $name %%>server",
    schema   => "<%%= $name %%>schema",
    host     => ($ENV{TEST_PGHOST} || "ERROR\n\nERROR: TEST_PGHOST not set\n\n"),
    connect_options => {
        PrintError => ($ENV{RM_PRINT_DB_ERRORS} ? 1 : 0),
        RaiseError => 0,
    }
);

__PACKAGE__->register_db(
    domain   => "dev",
    type     => "main",
    driver   => "Pg",
    database => ($ENV{<%%= $upname %%>_DEVDB} || "<%%= $name %%>server"),
    schema   => ($ENV{<%%= $upname %%>_DEVSCHEMA} || "<%%= $name %%>schema"),
    host     => ($ENV{PGHOST} || ""), # just fall through to defaults
    connect_options => {
        PrintError => 1,
        RaiseError => 0,
    }
);

__PACKAGE__->register_db(
    domain   => "live",
    type     => "main",
    driver   => "Pg",
    database => "<%%= $name %%>server",
    schema   => "<%%= $name %%>schema",
    host     => ($ENV{PGHOST} || "ERROR\n\nERROR: PGHOST not set\n\n"),
    connect_options => {
        PrintError => 1,
        RaiseError => 0,
    }
);

__PACKAGE__->default_domain(
     $ENV{HARNESS_ACTIVE} ? "test" :
     $ENV{<%%= $upname %%>_LIVE}    ? "live" :
     "dev" );

__PACKAGE__->default_type("main");

1;

