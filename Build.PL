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
    configure_requires => { 'Module::Build' => 0.40 },
    build_requires => {
        'Clustericious::Config' => '0.17',
        'Module::Build'        => '0.36',
        'Test::More'           => 0,
        'MojoX::Log::Log4perl' => 0,
        'Clustericious::Log'   => '0.05',
        'Mojolicious'          => '3.85',
        'Sub::Exporter'        => 0,
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
        'PlugAuth::Lite'       => '0.05',
      },
    add_to_cleanup      => [ 'Clustericious-*' ],
    #create_makefile_pl => 'traditional',
    share_dir => 'share',
    meta_merge => {
        no_index => { directory => [ 'share', 'util' ], },
        resources => {
            bugtracker => 'https://github.com/plicease/Clustericious/issues',
            homepage   => "http://perl.wdlabs.com/Clustericious",
            repository => 'git://github.com/plicease/Clustericious.git',
        }
    }
);

$builder->create_build_script();

1;
