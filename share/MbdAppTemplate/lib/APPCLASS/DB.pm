% my $class = shift;
=head1 NAME

<%= $class %>::DB - Manage the database connection.

=head1 DESCRIPTION

This manages the database connection for <%= $class %>.

See Rose::Planter::DB.

=cut

package <%= $class %>::DB;
use Clustericious::Config;
use base "Rose::Planter::DB";
use strict;
use warnings;

__PACKAGE__->register_databases(
    module_name  => "<%= $class %>",
    conf => Clustericious::Config->new("<%= $class %>")
);

1;

