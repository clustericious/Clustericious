package Clustericious;

use strict;
use warnings;
use 5.010;
use File::Spec;
use File::HomeDir;

# ABSTRACT: A framework for RESTful processing systems.
# VERSION

=head1 SYNOPSIS

Generate a new Clustericious application:

 % clustericious generate app MyApp

Basic application layout:

 package MyApp;
 
 use Mojo::Base qw( Clustericious::App );
 
 sub startup
 {
   my($self) = @_;
   # just like Mojolicious startup()
 }
 
 package MyApp::Routes;
 
 use Clustericious::RouteBuilder;
 
 # Mojolicious::Lite style routing
 get '/' => sub { shift->render(text => 'welcome to myapp') };

Basic testing for Clustericious application:

 use Test::Clustericious::Cluster;
 use Test::More tests => 4;
 
 # see Test::Clustericious::Cluster for more details
 # and examples.
 my $cluster = Test::Clustericious::Cluster->new;
 $cluster->create_cluster_ok('MyApp');    # 1
 
 my $url = $cluster->url;
 my $t   = $cluster->t;   # Test::Mojo object
 
 $t->get_ok("$url/")                      # 2
   ->status_is(200)                       # 3
   ->content_is('welcome to myapp');      # 4
 
 __DATA__
 
 @ etc/MyApp.conf
 ---
 url: <%= cluster->url %>

=head1 DESCRIPTION

Clustericious is a web application framework designed to create HTTP/RESTful
web services that operate on a cluster, where each service does one thing 
and ideally does it well.  The design goal is to allow for easy deployment
of applications.  Clustericious is based on the L<Mojolicious> and borrows
some ideas from L<Mojolicious::Lite> (L<Clustericious::RouteBuilder> is 
based on L<Mojolicious::Lite> routing).

Two examples of Clustericious applications on CPAN are L<Yars> the archive
server and L<PlugAuth> the authentication server.

=head1 FEATURES

Here are some of the distinctive aspects of Clustericious :

=over 4

=item *

Simplified route builder based on L<Mojolicious::Lite> (see L<Clustericious::RouteBuilder>).

=item *

Provides a set of default routes (e.g. /status, /version, /api) for consistent
interaction with Clustericious services (see L<Clustericious::RouteBuilder::Common>).

=item *

Introspects the routes available and publishes the API as /api.

=item *

Automatically handle different formats (YAML or JSON) depending on request 
(see L<Clustericious::Plugin::AutodataHandler>).

=item *

Interfaces with L<Clustericious::Client> to allow easy creation of
clients.

=item *

Uses L<Clustericious::Config> for configuration.

=item *

Uses L<Clustericious::Log> for logging.

=item *

Integrates with L<Module::Build::Database> and L<Rose::Planter>
to provide a basic RESTful CRUD interface to a database.

=item *

Provides 'stop' and 'start' commands, and high-level configuration
facilities for a variety of deployment options.

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

Brian Duggan

Curt Tilmes

=head1 SEE ALSO

=over 4

=item L<Raisin>

REST API framework based on Plack.  Development is more active than Clustericious at this time.

=item L<Clustericious::App>

Base class for Clustericious applications.

=item L<Clustericious::RouteBuilder::CRUD>

Create Remove Update Delete builder for Clustericious.

=item L<Clustericious::RouteBuilder::Search>

Build routes for searching for objects.

=item L<Clustericious::RouteBuilder::Common>

Common routes for all Clustericious applications.

=item L<Clustericious::Command::start>

Command to start a Clustericious application.

=cut

sub _testing
{
  state $test = 0;
  my($class, $new) = @_;
  $test = $new if defined $new;
  $test;
}

sub _config_path
{
  grep { -d $_ }
    map { File::Spec->catdir(@$_) } 
    grep { defined $_->[0] }
    (
      [ $ENV{CLUSTERICIOUS_CONF_DIR} ],
      (!_testing) ? (
        [ File::HomeDir->my_home, 'etc' ],
        [ File::HomeDir->my_dist_config('Clustericious') ],
        [ '', 'etc' ],
      ) : (),
    );
}

sub _slurp_pid ($)
{
  use autodie;
  my($fn) = @_;
  open my $fh, '<', $fn;
  my $pid = <$fh>;
  close $fh;
  chomp $pid;
  $pid;
}

sub _dist_dir
{
  require Path::Class::File;
  require Path::Class::Dir;
  $_ = __FILE__; s{(Clustericious).pm}{.$1.devshare}; -e $_
    ? Path::Class::File->new(__FILE__)->parent->parent->subdir('share')
    : do {
      require File::ShareDir;
      Path::Class::Dir->new(
        File::ShareDir::dist_dir('Clustericious'),
      );
    }
}

sub _generate_port
{
  require IO::Socket::INET;
  # this code is duplicated in Test::Clustericious::Command,
  # don't want to move it just FYI
  IO::Socket::INET->new(Listen => 5, LocalAddr => "127.0.0.1")->sockport
}

# Note sub _config_uncache also gets placed
# in this package, but it is defined in
# Clustericious::Config.

1;

