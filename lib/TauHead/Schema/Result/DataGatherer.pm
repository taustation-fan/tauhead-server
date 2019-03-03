use utf8;

package TauHead::Schema::Result::DataGatherer;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("data_gatherer");

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        extra             => { unsigned => 1 },
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "user_id",
    {   data_type      => "integer",
        extra          => { unsigned => 1 },
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "claimed",
    {   data_type => "tinyint",
        size => 1,
        default_value => 0,
        is_nullable => 0,
    },
    "held",
    {   data_type => "tinyint",
        size => 1,
        default_value => 0,
        is_nullable => 0,
    },
    "complete",
    {   data_type => "tinyint",
        size => 1,
        default_value => 0,
        is_nullable => 0,
    },
    "action",
    { data_type => "varchar", is_nullable => 0, size => 50 },
    "datetime_created",
    {   data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 0,
    },
    "datetime_updated",
    {   data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 0,
    },
    "message",
    { data_type => "varchar", is_nullable => 0, size => 255 },
    "json",
    { data_type => "mediumtext", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(
        name => 'c_h_c_a_dt',
        fields => ['claimed', 'held', 'complete', 'action', 'datetime_created'],
    );
}

__PACKAGE__->belongs_to(
    "user", "TauHead::Schema::Result::User",
    { id            => "user_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
