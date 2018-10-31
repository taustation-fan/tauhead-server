use utf8;

package TauHead::Schema::Result::VerifyEmailRequest;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("verify_email_request");

__PACKAGE__->add_columns(
    "guid",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "user_id",
    {   data_type      => "integer",
        extra          => { unsigned => 1 },
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "datetime",
    {   data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 0,
    },
);

__PACKAGE__->set_primary_key("guid");

__PACKAGE__->add_unique_constraint( "user_id", ["user_id"] );

__PACKAGE__->belongs_to(
    "user", "TauHead::Schema::Result::User",
    { id            => "user_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
