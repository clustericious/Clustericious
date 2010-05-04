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
    "peers" : [

       # Uses "a_local_app.conf" for key-value pairs.
       "a_local_app",

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

 print $c->peers->a_local_app->url; # comes from another config file
 print $c->peers->a_remote_app->url; # comes from the above file

=head1 DESCRIPTION

Read config files which are Mojo::Template's of JSON files.

After rendering the template and parsing the JSON, the resulting
object may be called using method calls or treated as hashes.

Config files are looked for in the following places (in order) :

    ~/app.conf
    ~/etc/app.conf
    /util/etc/app.conf
    /etc/app.conf

If the environment variable HARNESS_ACTIVE is set, then the
above directories are not used.  Instead the value of the
environment variable CLUSTERICIOUS_TEST_CONF_DIR is used
to find the configuration file.  This is automatically set
by Test::More and friends.

=head1 METHODS

=head2 peers

The special "peers" method is a list of sub-configurations --
a single name refers to another config file.  Alternatively,
a sub-configuration may be given.  See the SYNOPSIS.

=cut

package Clustericious::Config;

use strict;
use warnings;

use List::Util qw/first/;
use JSON::XS;
use Mojo::Template;
use Log::Log4perl qw/:easy/;
use Storable qw/dclone/;
use Data::Dumper;

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
        my @conf_dirs;
        if ($ENV{HARNESS_ACTIVE}) {
            LOGDIE "\n\nplease set CLUSTERICIOUS_TEST_CONF_DIR when running tests\n\n "
                unless $ENV{CLUSTERICIOUS_TEST_CONF_DIR};
            @conf_dirs = ( $ENV{CLUSTERICIOUS_TEST_CONF_DIR} );
        } else {
            @conf_dirs = ($ENV{HOME}, "$ENV{HOME}/etc", "/util/etc", "/etc" );
        }

        my $conf_file = "$arg.conf";
        my ($dir) = first { -e "$_/$conf_file" } @conf_dirs;
        LOGDIE "could not find $conf_file file in: @conf_dirs" unless $dir;

        TRACE "loading config file $dir/$conf_file";
        my $rendered = $mt->render_file("$dir/$conf_file" );
        $rendered or die "could not render $dir/$conf_file";
        $conf_data = $json->decode( $rendered );
    }
    my @peers = @{ $conf_data->{peers} || [] };
    $conf_data->{peers} = {};
    for my $p (@peers) {
        my $name = (ref $p ? $p->{name} : $p) or die "no name for peer ".Dumper($p);
        $conf_data->{peers}{$name} = $class->new($p);
    }
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
    our $AUTOLOAD;
    my $called = $AUTOLOAD;
    $called =~ s/.*:://g;
    die "$called not found in ".join ',',keys(%$self)
        if $called =~ /^_/ || !exists($self->{$called});
    my $value = $self->{$called};
    my $obj;
    if (ref $value eq 'HASH') {
        $obj = __PACKAGE__->new($value);
    }
    no strict 'refs';
    *{ __PACKAGE__ . "::$called" } = sub {
          my $self = shift;
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

