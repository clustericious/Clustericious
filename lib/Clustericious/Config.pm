=head1 NAME

Clustericious::Config - configuration files for clustericious nodes.

=head1 SYNOPSIS

 $ cat > ~/my_app.conf
 % my $url = "http://localhost:9999";
 % my $app = "my_app";
 % read_from "global";  # looks for global.conf
 % read_from common => ($url, $app); # looks for common.conf (w/ parameters)

 {
    "url"        : "<%= $url %>",
    "start_mode" : "daemon_prefork",
    "daemon_prefork" : {
        maxspare : 3,
    }
 }

 $ cat > ~/common.conf
 % my ($url, $app) = @_;
 {
    "daemon_prefork" : {
       "listen"   : "<%= $url %>",
       "pid"      : "/tmp/<%= $app %>.pid",
       "lock"     : "/tmp/<%= $app %>.lock",
       "maxspare" : 2,
       "start"    : 2
    }
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

=head1 DESCRIPTION

Read config files which are Mojo::Template's of JSON files.

After rendering the template and parsing the JSON, the resulting
object may be called using method calls or treated as hashes.

Config files are looked for in the following places (in order) :

    $ENV{CLUSTERICIOUS_CONF_DIR}
    ~/app.conf
    ~/etc/app.conf
    /util/etc/app.conf
    /etc/app.conf

If the environment variable HARNESS_ACTIVE is set, only $ENV{CLUSTERICIOUS_CONF_DIR}
is used.

The directive "read_from" may be used to read default settings
from another config file.  The first argument to read_from is the
basename of the config file.  Additional arguments will be
passed to the config file and can be read in by parsing @_
within that file.

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

sub new {
    my $class = shift;
    my @t_args = (ref $_[-1] eq 'ARRAY' ? @{( pop )} : () );
    my $arg = $_[0];
    ($arg = caller) =~ s/:.*$// unless $arg; # Determine from caller's class

    my $conf_data;

    my $json = JSON::XS->new;
    my $mt = Mojo::Template->new(namespace => 'Clustericious::Config::Plugin')->auto_escape(0);

    if (ref $arg eq 'SCALAR') {
        my $rendered = $mt->render($$arg, @t_args);
        die $rendered if ( (ref($rendered)) =~ /Exception/ );
        $conf_data = $json->decode( $rendered );
    } elsif (ref $arg eq 'HASH') {
        $conf_data = dclone $arg;
    } elsif ($ENV{HARNESS_ACTIVE} && !$ENV{CLUSTERICIOUS_CONF_DIR}) {
        $conf_data = {};
    } else {
        my @conf_dirs;

        @conf_dirs = $ENV{CLUSTERICIOUS_CONF_DIR} if defined( $ENV{CLUSTERICIOUS_CONF_DIR} );

        push @conf_dirs, ( $ENV{HOME}, "$ENV{HOME}/etc", "/util/etc", "/etc" ) unless $ENV{HARNESS_ACTIVE};
        my $conf_file = "$arg.conf";
        my ($dir) = first { -e "$_/$conf_file" } @conf_dirs;
        LOGDIE "could not find $conf_file file in: @conf_dirs" unless $dir;

        TRACE "reading from config file $dir/$conf_file";
        my $rendered = $mt->render_file("$dir/$conf_file", @t_args );
        die $rendered if ( (ref $rendered) =~ /Exception/ );
        $conf_data = $json->decode( $rendered );
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
    our $AUTOLOAD;
    my $called = $AUTOLOAD;
    $called =~ s/.*:://g;
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

