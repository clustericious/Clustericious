package Clustericious::Commands;

use strict;
use warnings;

use Clustericious::Config;

use base 'Mojolicious::Commands';

__PACKAGE__->attr(namespaces => sub { [qw/Clustericious::Command
                                          Mojolicious::Command
                                          Mojo::Command/] });

sub start {
   my $self = shift;

   my @args = @_ ? @_ : @ARGV;

   my $config = Clustericious::Config->new($ENV{MOJO_APP});

   unless (@args)
   {
       push(@args, $config->{start_mode});
       while (my ($key, $value) = each %{$config->{$config->{start_mode}}})
       {
           push(@args, "--$key", "$value");
       }
   }

   $self->SUPER::start(@args);
}

1;
