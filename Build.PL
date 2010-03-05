#!/usr/bin/env perl

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Clustericious',
    license             => 'perl',
    dist_author         => q{Brian Duggan <brian.duggan@nasa.gov>},
    dist_version_from   => 'lib/Clustericious.pm',
    dist_abstract       => 'Mojo and HTTP based cluster framework',
    build_requires => {
        'Test::More'           => 0,
        'MojoX::Log::Log4perl' => 0,
        'Mojolicious'          => '0.999921',
      },
    add_to_cleanup      => [ 'Clustericious-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

1;

