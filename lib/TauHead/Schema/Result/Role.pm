use utf8;

package TauHead::Schema::Result::Role;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("role");

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        extra             => { unsigned => 1 },
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "name",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "display_label",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "description",
    { data_type => "mediumtext", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraints(
    "name", ["name"],
    "display_label", ["display_label"],
);

__PACKAGE__->has_many(
    "user_roles",
    "TauHead::Schema::Result::UserRole",
    { "foreign.role_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many( "users", "user_roles", "role", );

1;
