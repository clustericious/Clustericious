use strict;
use warnings;
use File::HomeDir::Test;
use Test::More;

BEGIN {
    plan skip_all => 'requires Rose::Planter 0.34 and DBD::SQLite: '
        unless eval q{ use Rose::Planter 0.34 (); use DBD::SQLite (); 1 };
}

package SomeService;

our $VERSION = '1.0';
use base 'Clustericious::App';

package SomeService::DB;

use base qw( Rose::Planter::DB );
use Clustericious::Config;
use YAML::XS qw( DumpFile );
use DBI;
use File::HomeDir;
use Test::More;

BEGIN {
    my $home = File::HomeDir->my_home;
    my $db_filename = "$home/database.sqlite";
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_filename", '', '', { RaiseError => 1, AutoCommit => 1 });
    $dbh->do(q{create table person (
        id integer primary key,
        first_name varchar not null,
        last_name varchar
    )});
    $dbh->do(q{create table employer (
        id integer primary key,
        name varchar not null,
        tax_id integer
    )});
    $dbh->do(q{ create table employment_contract (
        id integer primary key,
        person_id integer,
        employer_id integer,
        text terms
    )});
    undef $dbh;
    mkdir "$home/etc";
    DumpFile("$home/etc/SomeService.conf", {
        url => "http://localhost:1234/",
        db => {
            database => $db_filename,
            driver   => 'SQLite',
        },
    });

    __PACKAGE__->register_databases(
        module_name => 'SomeService',
        conf => Clustericious::Config->new('SomeService'),
    );
}

package SomeService::Objects;

use Rose::Planter
    loader_params => {
        class_prefix => 'SomeService::Object',
        db_class     => 'SomeService::DB',
    },
    convention_manager_params => {};
;

package SomeService::Routes;

use Clustericious::RouteBuilder;
use Clustericious::RouteBuilder::CRUD
    create   => { -as => "do_create" },
    read     => { -as => "do_read" }, 
    delete   => { -as => "do_delete" }, 
    update   => { -as => "do_update" }, 
    list     => { -as => "do_list" }, 
    defaults => { finder => "Rose::Planter" };
use Clustericious::RouteBuilder::Search
    search   => { -as => "do_search" },
    defaults => { finder => "Rose::Planter" };

get '/' => sub { shift->render_text("hello"); };

post  '/:items/search' => \&do_search;
get   '/:items/search' => \&do_search;
post  '/:table'        => [ table => Rose::Planter->regex_for_tables ] => \&do_create;
get   '/:table/*key'   => [ table => Rose::Planter->regex_for_tables ] => \&do_read;
post  '/:table/*key'   => [ table => Rose::Planter->regex_for_tables ] => \&do_update;
del   '/:table/*key'   => [ table => Rose::Planter->regex_for_tables ] => \&do_delete;
get   '/:table'        => [ table => Rose::Planter->regex_for_tables ] => \&do_list;

package main;

use Test::More tests => 42;
use Test::Mojo;
use File::Find qw( find );
use File::Basename qw( dirname );

my $t = Test::Mojo->new("SomeService");

$t->get_ok('/api')
  ->status_is(200);

$t->get_ok('/api/bogus_table')
  ->status_is(404);

$t->get_ok('/api/person')
  ->status_is(200)
  ->json_is('/columns/first_name/not_null', 1)
  ->json_is('/columns/first_name/rose_db_type', 'varchar')
  ->json_is('/columns/first_name/type', 'string')
  ->json_is('/columns/id/not_null', 0)
  ->json_is('/columns/id/rose_db_type', 'integer')
  ->json_is('/columns/id/type', 'integer')
  ->json_is('/columns/last_name/not_null', 0)
  ->json_is('/columns/last_name/rose_db_type', 'varchar')
  ->json_is('/columns/last_name/type', 'string')
  ->json_is('/primary_key/0', 'id');

find(
    {
        wanted => sub {
            my $name = $File::Find::name;
            return if -d $name || $name =~ /^\./;
            $name =~ s{^.*(Rose/DB/Object/Metadata/Column/.*?\.pm)$}{$1};
            eval qq{ require '$name'; };
            my $class = $name;
            $class =~ s{/}{::}g;
            $class =~ s/\.pm$//;
            return if $class =~ /^Rose::DB::Object::Metadata::Column::(Array|Scalar)$/;
            return if Clustericious::App::_dump_api_table_types($class->type) ne 'unknown';
            diag "not sure about type for $class";
        },
        no_chdir => 1,
    },
    dirname($INC{'Rose/DB/Object/Metadata/Column.pm'}) . "/Column",
);

foreach my $type (qw( character text varchar ))
{
  is Clustericious::App::_dump_api_table_types($type), 'string', "$type = string";
}

foreach my $type ('numeric', 'float', 'double precision', 'decimal')
{
  is Clustericious::App::_dump_api_table_types($type), 'numeric', "$type = numeric";
}

foreach my $type (qw( blob set time interval enum datetime bytea chkpass bitfield date boolean ))
{
  is Clustericious::App::_dump_api_table_types($type), $type, "$type = $type";
}

foreach my $type (qw( bigint integer bigserial serial ))
{
  is Clustericious::App::_dump_api_table_types($type), 'integer', "$type = integer";
}

foreach my $type ('epoch', 'epoch hires')
{
  is Clustericious::App::_dump_api_table_types($type), 'epoch', "$type = epoch";
}

foreach my $type ('timestamp', 'timestamp with time zone')
{
  is Clustericious::App::_dump_api_table_types($type), 'timestamp', "$type = timestamp";
}

1;
