% my $class = shift;
% my $name = lc $class;
#!/usr/bin/env perl
use Module::Build;
use strict;
use warnings;

my $builder = Module::Build->new(
    module_name         => '<%= $class %>',
    license             => 'perl',
    dist_abstract       => "<%= $class %> server",
    dist_version_from   => 'lib/<%= $class %>.pm',
    build_requires => {
        'Test::More'          => 0,
        'Clustericious'       => '0.04',
    },
    add_to_cleanup      => [ '<%= $class %>-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

1;
