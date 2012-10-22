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
        'Clustericious::Config' => '0.01',
        'IO::Prompt'            => 0, # see t/basic.t
        'Module::Build'        => '0.36',
        'Test::More'           => 0,
        'MojoX::Log::Log4perl' => 0,
        'Clustericious::Log'   => '0.05',
        'Mojolicious'          => '3.09',
        'Sub::Exporter'        => 0,
        'YAML::Syck'           => 0,
        'JSON::XS'             => 0,
        'YAML::XS'             => 0,
        'List::MoreUtils'      => 0,
        'File::ShareDir'       => 0,
        'Hash::Merge'          => 0,
        'File::Slurp'          => 0,
        'Sys::Hostname'        => 0,
        'IO::Scalar'           => 0,
        'File::HomeDir'        => 0,
        'File::HomeDir::Test'  => 0,
      },
    add_to_cleanup      => [ 'Clustericious-*' ],
    create_makefile_pl => 'traditional',
    share_dir => 'share'
);

$builder->create_build_script();

1;
