package Clustericious::Config;

use strict;
use warnings;
use 5.010001;

# ABSTRACT: Configuration files for Clustericious nodes.
our $VERSION = '0.9940_02'; # VERSION


use Clustericious::Config::Password;
use List::Util;
use JSON::XS;
use YAML::XS ();
use Mojo::Template;
use Log::Log4perl qw/:easy/;
use Storable;
use Clustericious::Config::Helpers ();
use Data::Dumper;
use Cwd ();
use Module::Build;
use File::HomeDir ();

our %Singletons;

sub _is_subdir {
    my ($child,$parent) = @_;
    my $p = Cwd::abs_path($parent);
    my $c = Cwd::abs_path($child);
    return ($c =~ m[^\Q$p\E]) ? 1 : 0;
}

my $is_test = 0;
sub _testing {
  my($class, $new) = @_;
  $is_test = $new if defined $new;
  $is_test;
}

our $class_suffix = {};
sub _uncache {
    my($class, $name) = @_;
    delete $Clustericious::Config::Singletons{$name};
    $class_suffix->{$name} //= 1;
    $class_suffix->{$name}++;
}

sub pre_rendered { }
sub rendered { }


sub new {
    my $class = shift;
    my %t_args = (ref $_[-1] eq 'ARRAY' ? @{( pop )} : () );
    my $arg = $_[0];
    ($arg = caller) =~ s/:.*$// unless $arg; # Determine from caller's class
    return $Singletons{$arg} if exists($Singletons{$arg});

$DB::single = 1;    
    my $we_are_testing_this_module = 0;
    if(__PACKAGE__->_testing) {
        $we_are_testing_this_module = 0;
    }

    my $conf_data;

    my $json = JSON::XS->new;
    
    state $package_counter = 0;
    my $namespace = "Clustericious::Config::TemplatePackage::Package$package_counter";
    eval qq{ package $namespace; use Clustericious::Config::Helpers; };
    die $@ if $@;
    $package_counter++;
    
    my $mt = Mojo::Template->new(namespace => $namespace)->auto_escape(0);
    $mt->prepend( join "\n", map " my \$$_ = q{$t_args{$_}};", sort keys %t_args );

    my $filename;
    if (ref $arg eq 'SCALAR') {
        $class->pre_rendered( $$arg );
        my $rendered = $mt->render($$arg);
        $class->rendered( SCALAR => $rendered );
        die $rendered if ( (ref($rendered)) =~ /Exception/ );
        my $type = $rendered =~ /^---/ ? 'yaml' : 'json';
        $conf_data = $type eq 'yaml' ?
           eval { YAML::XS::Load( $rendered ); }
         : eval { $json->decode( $rendered ); };
        LOGDIE "Could not parse $type \n-------\n$rendered\n---------\n$@\n" if $@;
    } elsif (ref $arg eq 'HASH') {
        $conf_data = Storable::dclone $arg;
    } elsif (
          $we_are_testing_this_module
          && !(
              $ENV{CLUSTERICIOUS_CONF_DIR}
              && _is_subdir( $ENV{CLUSTERICIOUS_CONF_DIR}, Cwd::getcwd() )
          )) {
          $conf_data = {};
    } else {
        my @conf_dirs;

        @conf_dirs = $ENV{CLUSTERICIOUS_CONF_DIR} if defined( $ENV{CLUSTERICIOUS_CONF_DIR} );

        push @conf_dirs, ( File::HomeDir->my_home . "/etc", "/util/etc", "/etc" ) unless $we_are_testing_this_module || __PACKAGE__->_testing;
        my $conf_file = "$arg.conf";
        $conf_file =~ s/::/-/g;
        my ($dir) = List::Util::first { -e "$_/$conf_file" } @conf_dirs;
        if ($dir) {
            TRACE "reading from config file $dir/$conf_file";
            $filename = "$dir/$conf_file";
            $class->pre_rendered( $filename );
            my $rendered = $mt->render_file($filename);
            $class->rendered( $filename => $rendered );
            die $rendered if ( (ref $rendered) =~ /Exception/ );
            my $type = $rendered =~ /^---/ ? 'yaml' : 'json';
            if ($ENV{CL_CONF_TRACE}) {
                warn "configuration ($type) : \n";
                warn $rendered;
            }
            $conf_data =
              $type eq 'yaml'
              ? eval { YAML::XS::Load($rendered) }
              : eval { $json->decode($rendered) };
            LOGDIE "Could not parse $type\n-------\n$rendered\n---------\n$@\n" if $@;
        } else {
            TRACE "could not find $conf_file file in: @conf_dirs" unless $dir;
            $conf_data = {};
        }
    }
    $conf_data ||= {};
    Clustericious::Config::Helpers->_do_merges($conf_data);
    _add_heuristics($filename,$conf_data);
    # Use derived classes so that AUTOLOADING keeps namespaces separate
    # for various apps.
    if ($class eq __PACKAGE__) {
        if (ref $arg) {
            $arg = "$arg";
            $arg =~ tr/a-zA-Z0-9//cd;
        }
        $class = join '::', $class, 'App', $arg;
        $class .= $class_suffix->{$arg} if $class_suffix->{$arg};
        my $dome = '@'."$class"."::ISA = ('".__PACKAGE__. "')";
        eval $dome;
        die "error setting ISA : $@" if $@;
    }
    bless $conf_data, $class;
}

sub _add_heuristics {
    my $filename = shift;
    # Account for some mojo api changes
    my $conf_data = shift;
    if ($conf_data->{hypnotoad} && !ref($conf_data->{hypnotoad}{listen})) {
        warn "# hypnotoad->listen should be an arrayref in $filename\n";
        $conf_data->{hypnotoad}{listen} = [ $conf_data->{hypnotoad}{listen} ];
    }


}


sub dump_as_yaml {
    my $c = shift;
    return YAML::XS::Dump($c);
}

sub _stringify {
    my $self = shift;
    return join ' ', map { ($_, $self->{$_}) } sort keys %$self;
}

sub DESTROY {
}

sub AUTOLOAD {
    my $self = shift;
    my %args = @_;
    my $default = $args{default};
    my $default_exists = exists $args{default};
    our $AUTOLOAD;
    my $called = $AUTOLOAD;
    $called =~ s/.*:://g;
    if ($default_exists && !exists($self->{$called})) {
        $self->{$called} = $args{default};
    }
    Carp::cluck "config element '$called' not found for ".(ref $self)." (".(join ',',keys(%$self)).")"
        if $called =~ /^_/ || !exists($self->{$called});
    my $value = $self->{$called};
    my $obj;
    my $invocant = ref $self;
    if (ref $value eq 'HASH') {
        $obj = $invocant->new($value);
    }
    no strict 'refs';
    *{ $invocant . "::$called" } = sub {
          my $self = shift;
          $self->{$called} = $default if $default_exists && !exists($self->{$called});
          die "'$called' not found in ".join ',',keys(%$self)
              unless exists($self->{$called});
          my $value = $self->{$called};
          return wantarray && (ref $value eq 'HASH' ) ? %$value
          : wantarray && (ref $value eq 'ARRAY') ? @$value
          :                       defined($obj)  ? $obj
          : Clustericious::Config::Password->is_sentinel($value) ? Clustericious::Config::Password->get
          :                                        $value;
    };
    use strict 'refs';
    $self->$called;
}


sub set_singleton {
    my $class = shift;
    my $app = shift;
    my $obj = shift;
    our %Singletons;
    $Singletons{$app} = $obj;
}


1;


__END__
=pod

=head1 NAME

Clustericious::Config - Configuration files for Clustericious nodes.

=head1 VERSION

version 0.9940_02

=head1 SYNOPSIS

In your ~/etc/MyApp.conf file:

 ---
 % extends_config 'global';
 % extends_config 'hypnotoad', url => 'http://localhost:9999', app => 'MyApp';

 url : http://localhost:9999
 start_mode : hypnotoad
 hypnotoad :
    - heartbeat_timeout : 500
 
 arbitrary_key: value

In your ~/etc/globa.conf file:

 ---
 somevar : somevalue

In your ~/etc/hypnotoad.conf:

 listen :
    - <%= $url %>
 # home uses File::HomeDir to find the calling users'
 # home directory
 pid_file : <%= home %>/<%= $app %>/hypnotoad.pid
 env :
    MOJO_HOME : <%= home %>/<%= $app %>

From a L<Clustericious::App>:

 package MyApp;
 
 use Mojo::Base qw( Clustericious::App );
 
 package MyApp::Routes;
 
 use Clustericious::RouteBuilder;
 
 get '/' => sub {
   my $c = shift;
   my $config = $c; # $config isa Clustericious::Config
   
   # returns the value if it is defined, foo otherwise
   my $value = $config->arbitrary_key(default => 'foo');
 };

From a script:

 use Clustericious::Config;
 
 my $c = Clustericious::Config->new("MyApp");
 my $c = Clustericious::Config->new( \$config_string );
 my $c = Clustericious::Config->new( \%config_data_structure );

 print $c->url;
 print $c->{url};

 print $c->hypnotoad->listen;
 print $c->hypnotoad->{listen};
 my %hash = $c->hypnotoad;
 my @ary  = $c->hypnotoad;

 # Supply a default value for a missing configuration parameter :
 $c->url(default => "http://localhost:9999");
 print $c->this_param_is_missing(default => "something_else");

 # Dump out the entire config as yaml
 print $c->dump_as_yaml;

=head1 DESCRIPTION

Clustericious::Config reads configuration files which are Mojo::Template's
of JSON or YAML files.  There should generally be an entry for
'url', which may be used by either a client or a server depending on
how this node in the cluster is being used.

After rendering the template and parsing the JSON, the resulting
object may be called using method calls or treated as hashes.

Config files are looked for in the following places (in order, where
"MyApp" is the name of the app) :

    $CLUSTERICIOUS_CONF_DIR/MyApp.conf
    $HOME/etc/MyApp.conf
    /util/etc/MyApp.conf
    /etc/MyApp.conf

The helper "extends_config" may be used to read default settings
from another config file.  The first argument to extends_config is the
basename of the config file.  Additional named arguments may be passed
to that config file and used as variables within that file.  After
reading another file, the hashes are merged (i.e. with Hash::Merge);
so values anywhere inside the data structure may be overridden.

YAML config files must begin with "---", otherwise they are interpreted
as JSON.

This module provides a number of helpers
which can be used to get system details (such as the home directory of
the calling user or to prompt for passwords).  See L<Clustericious::Config::Helpers>
for details.

=head1 CONSTRUCTOR

=head2 new

Create a new Clustericious::Config object.  See the SYNOPSIS for
possible invocations.

=head1 METHODS

=head2 $config-E<gt>dump_as_yaml

Returns a string with the configuration encoded as YAML.

=head2 Clustericious::Config->set_singleton

Cache a config object to be returned by the constructor.  Usage:

 Clustericicious::Config->set_singleton(App => $object);

=head1 CAVEATS

Some filesystems do not support filenames with a colon
(:) character in them, so for apps with a double colon
in them (for example L<Clustericious::HelloWorld>),
a single dash character will be substituted for the name
(for example C<Clustericious-HelloWorld.conf>).

=head1 NOTES

This is a beta release. The API may change without notice.

=head1 SEE ALSO

L<Mojo::Template>, L<Hash::Merge>, L<Clustericious>, L<Clustericious::Client>, L<Clustericious::Config::Helpers>

=head1 AUTHOR

original author: Brian Duggan

current maintainer: Graham Ollis <plicease@cpan.org>

contributors:

Curt Tilmes

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

