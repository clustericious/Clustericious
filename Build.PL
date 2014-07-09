
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "A framework for RESTful processing systems.",
  "dist_author" => [
    "Graham Ollis <plicease\@cpan.org>"
  ],
  "dist_name" => "Clustericious",
  "dist_version" => "0.9937",
  "license" => "perl",
  "module_name" => "Clustericious",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Clustericious::Config" => "0.28",
    "Clustericious::Log" => "0.15",
    "File::HomeDir" => "0.91",
    "File::ShareDir" => 0,
    "File::Slurp" => 0,
    "JSON::XS" => 0,
    "List::MoreUtils" => 0,
    "Log::Log4perl" => 0,
    "MojoX::Log::Log4perl" => 0,
    "Mojolicious" => "4.31",
    "Path::Class" => 0,
    "PlugAuth::Lite" => "0.06",
    "Sub::Exporter" => 0,
    "Test::More" => 0,
    "YAML::XS" => 0,
    "perl" => "v5.10.0"
  },
  "script_files" => [
    "bin/clustericious"
  ],
  "share_dir" => {
    "dist" => "share"
  },
  "test_requires" => {
    "IO::Scalar" => 0,
    "PlugAuth::Lite" => "0.06",
    "Test::Clustericious::Cluster" => "0.09",
    "Test::Clustericious::Config" => 0,
    "autodie" => 0
  }
);


my %fallback_build_requires = (
  "IO::Scalar" => 0,
  "Module::Build" => "0.3601",
  "PlugAuth::Lite" => "0.06",
  "Test::Clustericious::Cluster" => "0.09",
  "Test::Clustericious::Config" => 0,
  "autodie" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
