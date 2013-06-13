=head1 NAME

Clustericious::App - Clustericious app base class

=head1 SYNOPSIS

 use Mojo::Base 'Clustericious::App';
 
=head1 DESCRIPTION

This class is the base class for all Clustericious applications.  It
inherits everything from L<Mojolicious> and adds a few Clustericious
specific methods documented here.

=head1 SUPER CLASS

L<Mojolicious>

=cut

package Clustericious::App;

use List::Util qw/first/;
use List::MoreUtils qw/uniq/;
use MojoX::Log::Log4perl;
use Mojo::UserAgent;
use Clustericious::Templates;
use Mojo::ByteStream qw/b/;
use Data::Dumper;
use Clustericious::Log;
use Mojo::URL;
use JSON::XS;
use Scalar::Util qw/weaken/;
use Mojo::Base 'Mojolicious';
use File::HomeDir ();

use Clustericious::Controller;
use Clustericious::Renderer;
use Clustericious::RouteBuilder::Common;
use Clustericious::Config;
use Clustericious::Commands;

our $VERSION = '0.9924_01';

sub _have_rose {
    return 1 if Rose::Planter->can("tables");
}

has commands => sub {
  my $commands = Clustericious::Commands->new(app => shift);
    weaken $commands->{app};
    return $commands;
};

use warnings;
use strict;

our @Confdirs = $ENV{TEST_HARNESS} ?
   ($ENV{CLUSTERICIOUS_TEST_CONF_DIR}) :
   (File::HomeDir->my_home, File::HomeDir->my_home . "/etc", "/util/etc", "/etc" );

{
no warnings 'redefine';
sub Math::BigInt::TO_JSON {
    my $val = shift;
    my $copy = "$val";
    my $i = 0 + $copy;
    return $i;
}
}

=head1 METHODS

=head2 $app-E<gt>startup

Adds the autodata_handler plugin, common routes,
and sets up logging for the client using log::log4perl.

=cut

sub startup {
    my $self = shift;

    $self->controller_class('Clustericious::Controller');
    $self->renderer(Clustericious::Renderer->new());
    $self->renderer->classes([qw/Clustericious::Templates/]);
    my $home = $self->home;
    $self->renderer->paths([ $home->rel_dir('templates') ]);

    $self->init_logging();
    $self->secret( (ref $self || $self) );

    $self->plugins->namespaces(['Mojolicious::Plugin','Clustericious::Plugin']);
    my $config = Clustericious::Config->new(ref $self);
    my $auth_plugin;
    if(my $auth_config = $config->plug_auth(default => '')) {
        $self->log->info("Loading auth plugin plug_auth");
        $auth_plugin = $self->plugin('plug_auth', plug_auth => $auth_config);
    } elsif($auth_config = $config->simple_auth(default => '')) {
        $self->log->info("Loading auth plugin simple_auth [deprecated]");
        $auth_plugin = $self->plugin('plug_auth', plug_auth => $auth_config);
    } else {
        $self->log->info("No auth configured");
    }

    my $r = $self->routes;
    # "Common" ones are not overrideable.
    Clustericious::RouteBuilder::Common->add_routes($self);
    Clustericious::RouteBuilder->add_routes($self, $auth_plugin);
    # "default" ones are :
    # Clustericious::RouteBuilder::Default->add_routes($self);

    $self->plugin('AutodataHandler');
    $self->plugin('DefaultHelpers');
    $self->plugin('TagHelpers');
    $self->plugin('EPLRenderer');
    $self->plugin('EPRenderer');
    if($Mojolicious::VERSION < 4.0) {
        # removed from mojo 4.0
        $self->plugin('RequestTimer');
        $self->plugin('PoweredBy');
    }

    # Helpers
    if (my $base = $config->url_base(default => '')) {
        $self->helper( base_tag => sub { b( qq[<base href="$base" />] ) } );
    }
    my $url = $config->url(default => '') or do {
        $self->log->warn("Configuration file should contain 'url'.") unless $ENV{HARNESS_ACTIVE};
    };

    $self->helper( _clustericious_config => sub { $config } );
    $self->helper( url_with => sub {
        my $c = shift;
        my $q = $c->req->url->clone->query;
        my $url = $c->url_for->clone;
        $url->query($q);
        $url;
    });

    $self->helper( render_moved => sub {
        my $c = shift;
        $c->res->code(301);
        my $where = $c->url_for(@_)->to_abs;
        $c->res->headers->location($where);
        $c->render(text => "moved to $where");
    } );

    # See http://groups.google.com/group/mojolicious/browse_thread/thread/000e251f0748c997
    my $murl = Mojo::URL->new($url);
    my $part_count = @{ $murl->path->parts };
    if ($part_count > 0 ) {
        $self->hook(before_dispatch  => sub {
            my $c = shift;
            if (@{ $c->req->url->base->path->parts } > 0) {
                # subrequest
                my @extra = splice @{ $c->req->url->base->path->parts }, -$part_count;
            }
            push @{ $c->req->url->base->path->parts },
              splice @{ $c->req->url->path->parts }, 0, $part_count;
        });
    }

    $self->hook( before_dispatch => sub {
        Log::Log4perl::MDC->put(remote_ip => shift->tx->remote_address || 'unknown');
    });

    if ( my $cors_allowed_origins = $config->cors_allowed_origins( default => '*' ) ) {
        $self->hook(
            after_dispatch => sub {
                my $c = shift;
                $c->res->headers->add( 'Access-Control-Allow-Origin' => '*' );
                $c->res->headers->add( 'Access-Control-Allow-Headers' => 'Authorization' );
            }
        );
    }

}

=head2 $app-E<gt>init_logging

Initializing logging using ~/etc/log4perl.conf

=cut

sub init_logging {
    my $self = shift;

    my $logger = Clustericious::Log->init_logging(ref $self || $self);

    $self->log( $logger );
}

=head2 $app-E<gt>dump_api

Dump out the API for this REST server.

=cut

sub dump_api {
    my $self = shift;
    my $routes = shift || $self->routes->children;
    my @all;
    for my $r (@$routes) {
        my $pat = $r->pattern;
        $pat->_compile;
        my %placeholders = map { $_ => "<$_>" } @{ $pat->placeholders };
        my $method = uc join ',', @{ $r->via || ["GET"] };
        if (_have_rose() && $placeholders{table}) {
            for my $table (Rose::Planter->tables) {
                $placeholders{table} = $table;
                my $pat = $pat->pattern;
                $pat =~ s/:table/$table/;
                push @all, "$method $pat";
            }
        } elsif (_have_rose() && $placeholders{items}) {
            for my $plural (Rose::Planter->plurals) {
                $placeholders{items} = $plural;
                my $line = $pat->render(\%placeholders);
                push @all, "$method $line";
            }
        } elsif (defined($pat->pattern)) {
            push @all, join ' ', $method, $pat->pattern;
        } else {
            push @all, $self->dump_api($r->children);
        }
    }
    return uniq sort @all;
}

=head2 $app-E<gt>dump_api_table( $table )

Dump out the column information for the given table.

=cut

sub _dump_api_table_types
{
    my($rose_type) = @_;
    return 'datetime' if $rose_type =~ /^datetime/;
    state $types = {
        (map { $_ => 'string' } qw( character text varchar )),
        (map { $_ => 'numeric' } 'numeric', 'float', 'double precision','decimal'),
        (map { $_ => $_ } qw( blob set time interval enum bytea chkpass bitfield date boolean )),
        (map { $_ => 'integer' } qw( bigint integer bigserial serial )),
        (map { $_ => 'epoch' } 'epoch', 'epoch hires'),
        (map { $_ => 'timestamp' } 'timestamp', 'timestamp with time zone'),
    };
    return $types->{$rose_type} // 'unknown';
}

sub dump_api_table
{
    my($self, $table) = @_;
    return unless _have_rose();
    my $class = Rose::Planter->find_class($table);
    return unless defined $class;

    return {
        columns => {
            map {
                $_->name => {
                    rose_db_type => $_->type,
                    not_null     => $_->not_null,
                    type         => _dump_api_table_types($_->type),
                } } $class->meta->columns
            },
        primary_key => [
            map { $_->name } $class->meta->primary_key_columns
        ],
    };
}

=head2 $app-E<gt>config

Returns the config (an instance of L<Clustericious::Config>) for the application.

=cut

sub config {
    my $app = shift;
    if (my $what = shift) {
        # Mojo config interface
        $app->_clustericious_config(@_)->{$what};
    } else {
        $app->_clustericious_config(@_);
    }
}

1;

=head1 SEE ALSO

L<Clustericious>

=cut