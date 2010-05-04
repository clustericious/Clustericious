=head1 NAME

Clustericious::Config - configuration files for clustericious nodes.

=head1 SYNOPSIS

 cat >> ~/my_app.conf
 % my $url = "http://localhost:9999";

 {
    "url"        : "<%= $url %>",
    "start_mode" : "daemon_prefork",
    "daemon_prefork" : {
       "listen"   : "<%= $url %>"
       "pid"      : "/tmp/my_app.pid",
       "lock"     : "/tmp/my_app.lock",
       "maxspare" : 2,
       "start"    : 2
    },
    "services" : [

       # Uses "a_local_app.conf" for key-value pairs.
       { "name" : "a_local_app" },

       # Local values override anything in "a_remote_app.conf".
       { "name" : "a_remote_app",
         "url"  : "http://localhost:9191"
       }
    ],
 }

 my $c = Clustericious::Config->new("my_app");
 my $c = Clustericious::Config->new( \$config_string );
 my $c = Clustericious::Config->new( \%config_data_structure );

 print $c->url;
 print $c->{url};

 print $c->daemon_prefork->listen;
 print $c->daemon_prefork->{listen};
 my %hash = $c->daemon_prefork;
 my @ary  = $c->daemon_prefork;

 print $c->services->other_app->url;

=head1 DESCRIPTION

Read config files which are Mojo::Template's of JSON files.

After rendering the template and parsing the JSON, the resulting
object may be called using method calls instead of keys.

Config files are looked for in the following places (in order) :

    ~/etc/app.conf
    ~/app.conf
    /util/etc/app.conf
    /etc/app.conf

If the environment variable TEST_HARNESS is set, then the
above directories are not used.  Instead the value of the
environment variable CLUSTERICIOUS_TEST_CONF_DIR is used
to find the configuration file.

=head1 METHODS

=head2 services

The special "services" method will automatically look for
another Clustericious::Config file named after the "name"
token in the "services" entry.  Values for a particular
service take predecedence over values given in the another
file.  See the SYNOPSIS.

=cut

package Clustericious::Config;

use strict;
use warnings;

use List::Util qw/first/;
use JSON::XS;
use Mojo::Template;
use Log::Log4perl qw/:easy/;
use Storable qw/dclone/;

sub new {
    my $class = shift;
    my $arg = $_[0] or die "no app name or conf data given to Clustericious::Config";
    my $conf_data;

    my $json = JSON::XS->new;
    my $mt = Mojo::Template->new->auto_escape(0);

    if (ref $arg eq 'SCALAR') {
        $conf_data = $json->decode( $mt->render($$arg) );
    } elsif (ref $arg eq 'HASH') {
        $conf_data = dclone $arg;
    } else {
        my @conf_dirs = $ENV{TEST_HARNESS} ?
            ($ENV{CLUSTERICIOUS_TEST_CONF_DIR}) :
            ($ENV{HOME}, "$ENV{HOME}/etc", "/util/etc", "/etc" );

        my $conf_file = "$arg.conf";
        my ($dir) = first { -e "$_/$conf_file" } @conf_dirs;

        TRACE "loading config file $dir/$conf_file";
        $conf_data = $json->decode( $mt->render_file("$dir/$conf_file" ) );
    }
    bless $conf_data, $class;
}

sub services {
    # TODO
    die "todo";
}

sub _stringify {
    my $self = shift;
    return join ' ', map { ($_, $self->{$_}) } sort keys %$self;
}

sub DESTROY {
}

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    my $called = $AUTOLOAD;
    $called =~ s/.*:://g;
    die "$called not found" if $called =~ /^_/ || !exists($self->{$called});
    my $value = $self->{$called};
    my $obj;
    if (ref $value eq 'HASH') {
        $obj = __PACKAGE__->new($value);
    }
    no strict 'refs';
    *{ __PACKAGE__ . "::$called" } = sub {
            wantarray && (ref $value eq 'HASH' ) ? %$value
          : wantarray && (ref $value eq 'ARRAY') ? @$value
          :                     defined($obj)  ? $obj
          :                                      $value;
    };
    use strict 'refs';
    $self->$called;
}

1;

