BEGIN {
  unless(eval q{ use 5.010001; 1}) {
    print "Perl 5.010001 or better required\n";
    exit;
  }
}

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
  "dist_version" => "0.9940_03",
  "license" => "perl",
  "module_name" => "Clustericious",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Data::Rmap" => 0,
    "DateTime::Format::DateParse" => 0,
    "DateTime::Format::ISO8601" => 0,
    "File::HomeDir" => "0.91",
    "File::ReadBackwards" => 0,
    "File::ShareDir" => 0,
    "File::Slurp" => 0,
    "Hash::Merge" => 0,
    "JSON::XS" => 0,
    "List::MoreUtils" => 0,
    "Log::Log4perl" => 0,
    "Log::Log4perl::Appender::TAP" => "0.02",
    "Module::Build" => "0.3601",
    "MojoX::Log::Log4perl" => 0,
    "Mojolicious" => "4.40",
    "Path::Class" => 0,
    "Sub::Exporter" => 0,
    "Term::Prompt" => 0,
    "Test::Builder::Module" => 0,
    "Test::More" => 0,
    "YAML::XS" => 0,
    "perl" => "5.010001"
  },
  "script_files" => [
    "bin/clustericious"
  ],
  "share_dir" => {
    "dist" => "share"
  },
  "test_requires" => {
    "IO::Scalar" => 0,
    "PlugAuth::Lite" => 0,
    "Test::Clustericious::Cluster" => "0.17",
    "autodie" => 0
  }
);


my %fallback_build_requires = (
  "IO::Scalar" => 0,
  "Module::Build" => "0.3601",
  "PlugAuth::Lite" => 0,
  "Test::Clustericious::Cluster" => "0.17",
  "autodie" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
