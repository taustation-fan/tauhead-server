use utf8;

package TauHead::Schema::Result::LoginFailure;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(
    'InflateColumn::DateTime',
);

__PACKAGE__->table("login_failure");

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "user_account_id",
    {   data_type      => "integer",
        is_foreign_key => 1,
        is_nullable    => 1,
    },
    "datetime",
    {   data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 0,
    },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
    "user_account", "TauHead::Schema::Result::UserAccount",
    { "foreign.id" => "self.user_account_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
