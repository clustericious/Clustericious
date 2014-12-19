package Test::Clustericious::Config;

use strict;
use warnings;
use v5.10;

BEGIN {
  unless($INC{'File/HomeDir/Test.pm'})
  {
    eval q{ use File::HomeDir::Test };
    die $@ if $@;
  }
}

use File::HomeDir;
use YAML::XS qw( DumpFile );
use File::Path qw( mkpath );
use Clustericious::Config;
use Mojo::Loader;

use base qw( Test::Builder::Module Exporter );

our @EXPORT = qw( create_config_ok create_directory_ok home_directory_ok create_config_helper_ok );
our @EXPORT_OK = @EXPORT;
our %EXPORT_TAGS = ( all => \@EXPORT );

my $config_dir;

sub _init
{
  $config_dir = File::HomeDir->my_home . "/etc";
  mkdir $config_dir;

  $ENV{CLUSTERICIOUS_CONF_DIR} = $config_dir;
  Clustericious::Config->_testing(1);
}

BEGIN { _init() }

# ABSTRACT: Test Clustericious::Config
# VERSION

=head1 SYNOPSIS

 use Test::Clustericious::Config;
 use Clustericious::Config;
 use Test::More tets => 2;
 
 create_config_ok 'Foo', { url => 'http://localhost:1234' };
 my $config = Clustericious::Config->new('Foo');
 is $config->url, "http://localhost:1234";

To test against a Clustericious application MyApp:

 use Test::Clustericious::Config;
 use Test::Clustericious;
 use Test::More tests => 3;

 create_config_ok 'MyApp', { x => 1, y => 2 }; 
 my $t = Test::Clustericious->new('MyApp');
 
 $t->get_ok('/');
 
 is $t->app->config->x, 1;

To test against multiple Clustericious applications MyApp1, MyApp2
(can also be the same app with different config):

 use Test::Clustericious::Config;
 use Test::Clustericious;
 use Test::More tests => 4;
 
 create_config_ok 'MyApp1', {};
 my $t1 = Test::Clustericious->new('MyApp1');
 
 $t1->get_ok('/');
 
 create_config_ok 'MyApp2', { my_app1_url => $t1->app_url };
 my $t2 = Test::Clustericious->new('MyApp2');
 
 $t2->get_ok('/');

=head1 DESCRIPTION

This module provides an interface for testing Clustericious
configurations, or Clustericious applications which use
a Clustericious configuration.

It uses L<File::HomeDir::Test> to isolate your test environment
from any configurations you may have in your C<~/etc>.  Keep
in mind that this means that C<$HOME> and friends will be in
a temporary directory and removed after the test runs.  It also
means that the caveats for L<File::HomeDir::Test> apply when
using this module as well (ie. this should be the first module
that you use in your test after C<use strict> and C<use warnings>).

=head1 FUNCTIONS

=head2 create_config_ok $name, $config, [$test_name]

Create a Clustericious config with the given C<$name>.
If C<$config> is a reference then it will create the 
configuration file with C<YAML::XS::DumpFile>, if
it is a scalar, it will will write the scalar out
to the config file.  Thus these three examples should
create a config with the same values (though in different
formats):

hash reference:

 create_config_ok 'Foo', { url => 'http://localhost:1234' }];

YAML:

 create_config_ok 'Foo', <<EOF;
 ---
 url: http://localhost:1234
 EOF

JSON:

 create_config_ok 'Foo', <<EOF;
 {"url":"http://localhost:1234"}
 EOF

In addition to being a test that will produce a ok/not ok
result as output, this function will return the full path
to the configuration file created.

=cut

sub create_config_ok ($;$$)
{
  my($config_name, $config, $test_name) = @_;

  my $fn = "$config_name.conf";
  $fn =~ s/::/-/g;
  
  unless(defined $config)
  {
    my $loader = Mojo::Loader->new;
    my $caller = caller;
    $loader->load($caller);
    $config = $loader->data($caller, "etc/$fn");
  }
  
  my $tb = __PACKAGE__->builder;  
  my $ok = 1;
  unless(defined $config)
  {
    $config = "---\n";
    $tb->diag("unable to locate text for $config_name");
    $ok = 0;
  }
  
  my $config_filename = "$config_dir/$fn";
  
  eval {
    if(ref $config)
    {
      DumpFile($config_filename, $config);
    }
    else
    {
      open my $fh, '>', $config_filename;
      print $fh $config;
      close $fh;
    }
  };
  if(my $error = $@)
  {
    $ok = 0;
    $tb->diag("exception: $error");
  }
  
  $test_name //= "create config for $config_name at $config_filename";
  
  # remove any cached copy if necessary
  Clustericious::Config->_uncache($config_name);

  $tb->ok($ok, $test_name);
  return $config_filename;
}

=head2 create_directory_ok $path, [$test_name]

Creates a directory in your test environment home directory.
This directory will be recursively removed when your test
terminates.  This function returns the full path of the 
directory created.

=cut

sub create_directory_ok ($;$)
{
  my($path, $test_name) = @_;
  
  my $fullpath = $path;
  $fullpath =~ s{^/}{};
  $fullpath = join('/', File::HomeDir->my_home, $fullpath);
  mkpath $fullpath, 0, 0700;
  
  $test_name //= "create directory $fullpath";
  
  my $tb = __PACKAGE__->builder;
  $tb->ok(-d $fullpath, $test_name);
  return $fullpath;
}

=head2 home_directory_ok [$test_name]

Tests that the temp home directory has been created okay.
Returns the full path of the home directory.

=cut

sub home_directory_ok (;$)
{
  my($test_name) = @_;
  
  my $fullpath = File::HomeDir->my_home;
  
  $test_name //= "home directory $fullpath";
  
  my $tb = __PACKAGE__->builder;
  $tb->ok(-d $fullpath, $test_name);
  return $fullpath;
}

=head2 create_config_helper_ok $helper_name, $helper_coderef, [ $test_name ]

Install a helper which can be called from within a configuration template.
Example:

 my $counter;
 create_config_helper_ok 'counter', sub { $counter++ };
 create_config_ok 'MyApp', <<EOF;
 ---
 one: <%= counter %>
 two: <%= counter %>
 three: <% counter %>
 EOF

=cut

sub create_config_helper_ok ($$;$)
{
  my($helper_name, $helper_code, $test_name) = @_;
  
  $test_name //= "create config helper $helper_name";
  
  require Clustericious::Config::Helpers;
  do {
    no strict 'refs';
    *{"Clustericious::Config::Helpers::$helper_name"} = $helper_code;
  };
  push @Clustericious::Config::Helpers::EXPORT, $helper_name;
  
  my $tb = __PACKAGE__->builder;
  $tb->ok(1, $test_name);
  return;
}

1;

=head1 EXAMPLES

Here is an (abbreviated) example from L<Yars> that show how to test against an app
where you need to know the port/url of the app in the configuration
file:

 use Test::Mojo;
 use Test::More tests => 1;
 use Test::Clustericious::Config;
 use Mojo::UserAgent;
 use Yars;
 
 my $t = Test::Mojo->new;
 $t->ua(do {
   my $ua = Mojo::UserAgent->new;
   create_config_ok 'Yars', {
     url => $ua->app_url,
     servers => [ {
       url => $ua->app_url,
     } ]
   };
   $ua->app(Yars->new);
   $ua
 };
 
 $t->get_ok('/status');

To see the full tests see t/073_tempdir.t in the L<Yars> distribution.

=cut
