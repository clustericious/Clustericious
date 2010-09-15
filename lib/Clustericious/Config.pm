=head1 NAME

Clustericious::Config - configuration files for clustericious nodes.

=head1 SYNOPSIS

 $ cat > ~/MyApp.conf
 % extends_config 'global';
 % extends_config 'common', url => 'http://localhost:9999', app => 'MyApp';

 {
    "start_mode" : "daemon_prefork",
    "daemon_prefork" : {
        maxspare : 3,
    }
 }

 $ cat > ~/global.conf
 {
    "some_var" : "some_value"
 }

 $ cat > ~/common.conf
 {
    "url" : "<%= $url %>",
    "daemon_prefork" : {
       "listen"   : "<%= $url %>",
       "pid"      : "/tmp/<%= $app %>.pid",
       "lock"     : "/tmp/<%= $app %>.lock",
       "maxspare" : 2,
       "start"    : 2
    }
 }

Then later in a program somewhere :

 my $c = Clustericious::Config->new("MyApp");
 my $c = Clustericious::Config->new( \$config_string );
 my $c = Clustericious::Config->new( \%config_data_structure );

 print $c->url;
 print $c->{url};

 print $c->daemon_prefork->listen;
 print $c->daemon_prefork->{listen};
 my %hash = $c->daemon_prefork;
 my @ary  = $c->daemon_prefork;

 # Supply a default value for a missing configuration parameter :
 $c->url(default => "http://example.com");
 print $c->this_param_is_missing(default => "something_else");

=head1 DESCRIPTION

Read config files which are Mojo::Template's of JSON files.

After rendering the template and parsing the JSON, the resulting
object may be called using method calls or treated as hashes.

Config files are looked for in the following places (in order, where
"MyApp" is the name of the app) :

    $ENV{CLUSTERICIOUS_CONF_DIR}/MyApp.conf
    ~/MyApp.conf
    ~/etc/MyApp.conf
    /util/etc/MyApp.conf
    /etc/MyApp.conf

If the environment variable HARNESS_ACTIVE is set,
and the current module::build object tells us that
the calling module is being tested, then only
$ENV{CLUSTERICIOUS_CONF_DIR} is used.

The helper "extends_config" may be used to read default settings
from another config file.  The first argument to extends_config is the
basename of the config file.  Additional named arguments may be passed
to that config file and used as variables within that file.

=head1 SEE ALSO

Mojo::Template

=cut

package Clustericious::Config;

use strict;
use warnings;

use List::Util qw/first/;
use JSON::XS;
use Mojo::Template;
use Log::Log4perl qw/:easy/;
use Storable qw/dclone/;
use Clustericious::Config::Plugin;
use Data::Dumper;
use Module::Build;

sub new {
    my $class = shift;
    my %t_args = (ref $_[-1] eq 'ARRAY' ? @{( pop )} : () );
    my $arg = $_[0];
    ($arg = caller) =~ s/:.*$// unless $arg; # Determine from caller's class

    my $we_are_testing_this_module = 0;
    if ($ENV{HARNESS_ACTIVE} and Module::Build->can("current")) {
        my $mb = Module::Build->current;
        $we_are_testing_this_module = $mb && $mb->module_name eq $arg;
    }

    my $conf_data;

    my $json = JSON::XS->new;
    my $mt = Mojo::Template->new(namespace => 'Clustericious::Config::Plugin')->auto_escape(0);
    $mt->prepend( join "\n", map " my \$$_ = q{$t_args{$_}};", sort keys %t_args );

    if (ref $arg eq 'SCALAR') {
        my $rendered = $mt->render($$arg);
        die $rendered if ( (ref($rendered)) =~ /Exception/ );
        $conf_data = eval { $json->decode( $rendered ); };
        LOGDIE "Could not parse\n-------\n$rendered\n---------\n$@\n" if $@;
    } elsif (ref $arg eq 'HASH') {
        $conf_data = dclone $arg;
    } elsif ($we_are_testing_this_module && !$ENV{CLUSTERICIOUS_CONF_DIR}) {
        $conf_data = {};
    } else {
        my @conf_dirs;

        @conf_dirs = $ENV{CLUSTERICIOUS_CONF_DIR} if defined( $ENV{CLUSTERICIOUS_CONF_DIR} );

        push @conf_dirs, ( $ENV{HOME}, "$ENV{HOME}/etc", "/util/etc", "/etc" ) unless $we_are_testing_this_module;
        my $conf_file = "$arg.conf";
        my ($dir) = first { -e "$_/$conf_file" } @conf_dirs;
        if ($dir) {
            TRACE "reading from config file $dir/$conf_file";
            my $rendered = $mt->render_file("$dir/$conf_file");
            die $rendered if ( (ref $rendered) =~ /Exception/ );
            $conf_data = eval { $json->decode( $rendered ) };
            LOGDIE "Could not parse\n-------\n$rendered\n---------\n$@\n" if $@;
        } else {
            TRACE "could not find $conf_file file in: @conf_dirs" unless $dir;
            $conf_data = {};
        }
    }
    Clustericious::Config::Plugin->do_merges($conf_data);
    bless $conf_data, $class;
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
    die "config element '$called' not found (".(join ',',keys(%$self)).")"
        if $called =~ /^_/ || !exists($self->{$called});
    my $value = $self->{$called};
    my $obj;
    if (ref $value eq 'HASH') {
        $obj = __PACKAGE__->new($value);
    }
    no strict 'refs';
    *{ __PACKAGE__ . "::$called" } = sub {
          my $self = shift;
          $self->{$called} = $default if $default_exists && !exists($self->{$called});
          die "'$called' not found in ".join ',',keys(%$self)
              unless exists($self->{$called});
          my $value = $self->{$called};
            wantarray && (ref $value eq 'HASH' ) ? %$value
          : wantarray && (ref $value eq 'ARRAY') ? @$value
          :                       defined($obj)  ? $obj
          :                                        $value;
    };
    use strict 'refs';
    $self->$called;
}

1;

