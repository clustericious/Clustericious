
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
  "dist_version" => "0.9934",
  "license" => "perl",
  "module_name" => "Clustericious",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Clustericious::Config" => "0.25",
    "Clustericious::Log" => "0.14",
    "Cwd" => 0,
    "Data::Dumper" => 0,
    "File::Basename" => 0,
    "File::Find" => 0,
    "File::HomeDir" => 0,
    "File::Path" => 0,
    "File::ShareDir" => 0,
    "File::Slurp" => 0,
    "JSON::XS" => 0,
    "List::MoreUtils" => 0,
    "List::Util" => 0,
    "Log::Log4perl" => 0,
    "MojoX::Log::Log4perl" => 0,
    "Mojolicious" => "3.85",
    "Path::Class" => 0,
    "PlugAuth::Lite" => "0.06",
    "Scalar::Util" => 0,
    "Sub::Exporter" => 0,
    "Sys::Hostname" => 0,
    "Test::More" => 0,
    "YAML::XS" => 0,
    "perl" => "v5.10.0"
  },
  "script_files" => [
    "bin/clustericious"
  ],
  "test_requires" => {
    "File::HomeDir::Test" => 0,
    "File::Temp" => 0,
    "IO::Scalar" => 0,
    "PlugAuth::Lite" => "0.06",
    "Test::Clustericious::Cluster" => "0.09",
    "Test::Clustericious::Config" => 0,
    "autodie" => 0
  }
);


my %fallback_build_requires = (
  "File::HomeDir::Test" => 0,
  "File::Temp" => 0,
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
