% my $class = shift;
=head1 NAME

<%= $class %>::Objects -- All model classes for <%= $class %>.

=head1 DESCRIPTION

Use this package to load all the <%= $class %>::Object::* classes.

=cut

package <%= $class %>::Objects;

use <%= $class %>::DB;
use Rose::Planter
        loader_params => {
            class_prefix => "<%= $class %>::Object",
            db_class     => "<%= $class %>::DB",
        },
        convention_manager_params => {};
1;
