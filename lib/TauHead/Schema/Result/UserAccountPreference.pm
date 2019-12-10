use utf8;

package TauHead::Schema::Result::UserAccountPreference;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("user_account_preference");

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        extra             => { unsigned => 1 },
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "user_account_id",
    {   data_type      => "integer",
        extra          => { unsigned => 1 },
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "preference_id",
    {   data_type         => "integer",
        extra             => { unsigned => 1 },
        is_foreign_key    => 1,
        is_nullable       => 0,
    },
    "value",
    { data_type => "varchar", is_nullable => 1, size => 255 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint( "user_account_id_preference_id",
    [ "user_account_id", "preference_id" ] );

__PACKAGE__->belongs_to(
    "user_account", "TauHead::Schema::Result::UserAccount",
    { id            => "user_account_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->belongs_to(
    "preference", "TauHead::Schema::Result::Preference",
    { id            => "preference_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
