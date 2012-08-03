% my $class = shift;
% my $name = lc $class;
#!/usr/bin/env perl

use strict;
use warnings;
use Module::Build::Database;

my $builder = Module::Build::Database->new(
    database_type       => "PostgreSQL",
    database_options => {
        name => "<%= $name %>server",
        schema => "<%= $name %>schema",
    },
    module_name         => '<%= $class %>',
    license             => 'perl',
    dist_abstract       => "<%= $class %> server",
    dist_version_from   => 'lib/<%= $class %>.pm',
    build_requires => {
        'Test::More'          => 0,
        'Clustericious'       => '0.04',
        'Test::Pod::Coverage' => 0,
        'Rose'                => 0,
        'DBD::Pg'             => 0,
        'Rose::Planter'       => '0.04',
        'DBIx::Connector'     => 0,
    },
    add_to_cleanup      => [ '<%= $class %>-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

1;
