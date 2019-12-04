use utf8;

package TauHead::Schema::Result::PasswordChangeRequest;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components('InflateColumn::DateTime');

__PACKAGE__->table("password_change_request");

__PACKAGE__->add_columns(
    "guid",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "user_account_id",
    {   data_type      => "integer",
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "datetime",
    {   data_type                 => "timestamp",
        datetime_undef_if_invalid => 1,
        is_nullable               => 0,
    },
);

__PACKAGE__->set_primary_key("guid");

__PACKAGE__->belongs_to(
    "user_account", "TauHead::Schema::Result::UserAccount",
    { id            => "user_account_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
