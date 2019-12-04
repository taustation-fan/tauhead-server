use utf8;

package TauHead::Schema::Result::UserAccountRole;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("user_account_role");

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "user_account_id",
    {   data_type      => "integer",
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "role_id",
    {   data_type         => "integer",
        is_foreign_key    => 1,
        is_nullable       => 0,
    },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint( "user_account_id_role_id",
    [ "user_account_id", "role_id" ] );

__PACKAGE__->belongs_to(
    "user_account", "TauHead::Schema::Result::UserAccount",
    { id            => "user_account_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->belongs_to(
    "role", "TauHead::Schema::Result::Role",
    { id            => "role_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
