package Clustericious::Config;

use strict;
use warnings;
use 5.010;
use Clustericious;
use Clustericious::Config::Password;
use List::Util ();
use JSON::MaybeXS ();
use YAML::XS ();
use Mojo::Template;
use Log::Log4perl qw( :nowarn );
use Storable ();
use Clustericious::Config::Helpers ();
use Cwd ();
use File::HomeDir ();
use Mojo::URL;
use File::Spec;
use File::Temp ();
use Carp ();

# ABSTRACT: Configuration files for Clustericious nodes.
# VERSION

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
   my $value1 = $config->arbitrary_key1(default => 'foo');
   
   # returns the value if it is defined, bar otherwise
   # code reference is only called if the value is NOT
   # defined
   my $value2 = $config->arbitrary_key2(default => sub { 'bar' });
 };

From a script:

 use Clustericious::Config;
 
 my $c = Clustericious::Config->new("MyApp");
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

=cut

our %singletons;

sub _is_subdir {
  Carp::carp "Clustericious::Config#_is_subdir is deprecated";
  my ($child,$parent) = @_;
  my $p = Cwd::abs_path($parent);
  my $c = Cwd::abs_path($child);
  return ($c =~ m[^\Q$p\E]) ? 1 : 0;
}

our $class_suffix = {};
sub _uncache {
  my($class, $name) = @_;
  delete $singletons{$name};
  $class_suffix->{$name} //= 1;
  $class_suffix->{$name}++;
}

=head1 CONSTRUCTOR

=head2 new

Create a new Clustericious::Config object.  See the SYNOPSIS for
possible invocations.

=cut

sub new {
  my $class = shift;

  my $logger = Log::Log4perl->get_logger(__PACKAGE__);

  # (undocumented; for now)
  # callback is used by the configdebug command;
  # may be used elsewise at a later time
  my $callback = ref $_[-1] eq 'CODE' ? pop : sub {};

  my %t_args = (ref $_[-1] eq 'ARRAY' ? @{( pop )} : () );

  my $arg = $_[0];
  ($arg = caller) =~ s/:.*$// unless $arg; # Determine from caller's class
  return $singletons{$arg} if exists($singletons{$arg});

  my $conf_data;

  state $package_counter = 0;
  my $namespace = "Clustericious::Config::TemplatePackage::Package$package_counter";
  eval qq{ package $namespace; use Clustericious::Config::Helpers; };
  die $@ if $@;
  $package_counter++;
    
  my $mt = Mojo::Template->new(namespace => $namespace)->auto_escape(0);
  $mt->prepend( join "\n", map " my \$$_ = q{$t_args{$_}};", sort keys %t_args );

  if(ref $arg eq 'HASH')
  {
    $conf_data = Storable::dclone $arg;
  }
  else
  {
    my $filename;
  
    if (ref $arg eq 'SCALAR')
    {
      Carp::carp("string scalar configuration is deprecated");
      $filename = File::Spec->catfile(File::Temp::tempdir(CLEANUP => 1), "Scalar@{[int $arg]}.conf");
      my $fh;
      open($fh, '>', $filename);
      print $fh $$arg;
      close $fh;
    }
    else
    {
      my $name = $arg;
      $name =~ s/::/-/g;      
      ($filename) = 
        List::Util::first { -f $_ } 
        map { File::Spec->catfile($_, "$name.conf") } 
        Clustericious->_config_path;
      
      unless($filename)
      {
        $logger->trace("could not find $name file.") if $logger->is_trace;
        $conf_data = {};
      }
    }
    
    if ($filename) {
      $logger->trace("reading from config file $filename") if $logger->is_trace;
      $callback->(pre_rendered => $filename);
      my $rendered = $mt->render_file($filename);
      $callback->(rendered => $filename => $rendered);

      die $rendered if ( (ref $rendered) =~ /Exception/ );
      my $type = $rendered =~ /^---/ ? 'yaml' : 'json';

      Carp::carp("JSON configuration file is deprecated") if $type eq 'json';

      $conf_data =$type eq 'yaml'
        ? eval { YAML::XS::Load($rendered) }
        : eval { JSON::MaybeXS::decode_json $rendered };
      $logger->logdie("Could not parse $type\n-------\n$rendered\n---------\n$@\n") if $@;
    }
  }

  $conf_data ||= {};
  Clustericious::Config::Helpers->_do_merges($conf_data);

  # Use derived classes so that AUTOLOADING keeps namespaces separate
  # for various apps.
  if ($class eq __PACKAGE__)
  {
    if (ref $arg)
    {
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

=head1 METHODS

=head2 dump_as_yaml

B<DEPRECATED>

 my $yaml_string = $config->dump_as_yaml;

Returns a string with the configuration encoded as YAML.

=cut

sub dump_as_yaml {
  Carp::carp "Clustericious::Config#dump_as_yaml is deprecated";
  my($self) = @_;
  return YAML::XS::Dump($self);
}

# defined so that AUTOLOAD doesn't get called
# when config falls out of scope.
sub DESTROY {
}

sub AUTOLOAD {
  my($self, %args) = @_;
  
  # NOTE: I hope to deprecated and later remove defining defaults in this way in the near future.
  my $default = $args{default};
  my $default_exists = exists $args{default};

  our $AUTOLOAD;
  my $called = $AUTOLOAD;
  $called =~ s/.*:://g;

  my $value = $self->{$called};
  my $invocant = ref $self;
  my $obj = ref $value eq 'HASH' ? $invocant->new($value) : undef;

  my $sub = sub {
    my $self = shift;
    my $value;
          
    if(exists $self->{$called})
    {
      $value = $self->{$called};
    }
    elsif($default_exists)
    {
      $value = $self->{$called} = ref $default eq 'CODE' ? $default->() : $default;
    }
    else
    {
      Carp::croak "'$called' configuration item not found.  Values present: @{[keys %$self]}";
    }
          
    if(wantarray)
    {
      return %$value if ref $value eq 'HASH';
      return @$value if ref $value eq 'ARRAY'; 
    }
    return $obj if $obj;
    return Clustericious::Config::Password->is_sentinel($value) ? Clustericious::Config::Password->get : $value;
  };
  do { no strict 'refs'; *{ $invocant . "::$called" } = $sub };
  $sub->($self);
}

=head2 set_singleton

B<DEPRECATED>

 Clustericious::Config->set_singleton;

Cache a config object to be returned by the constructor.  Usage:

 Clustericicious::Config->set_singleton(App => $object);

=cut

sub set_singleton {
  Carp::carp "Clustericious::Config#set_singleton is deprecated";
  my($class, $app, $obj) = @_;
  $singletons{$app} = $obj;
}

sub _default_start_mode {
  my $self = shift;
  $self->start_mode(default => sub {
    $self->hypnotoad(default => sub {
      my $url = Mojo::URL->new($self->url);
      {
        pid_file => File::Spec->catfile( File::HomeDir->my_dist_data("Clustericious", { create => 1 } ), 'hypnotoad-' . $url->port . '-' . $url->host . '.pid' ),
        listen => [
          $url->to_string,
        ],
      }
    });
    [ 'hypnotoad' ];
  });
}

=head1 CAVEATS

Some filesystems do not support filenames with a colon
(:) character in them, so for apps with a double colon
in them (for example L<Clustericious::HelloWorld>),
a single dash character will be substituted for the name
(for example C<Clustericious-HelloWorld.conf>).

=head1 SEE ALSO

L<Mojo::Template>, L<Hash::Merge>, L<Clustericious>, L<Clustericious::Client>, L<Clustericious::Config::Helpers>

=cut

1;

