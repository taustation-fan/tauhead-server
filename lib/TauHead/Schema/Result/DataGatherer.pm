use utf8;

package TauHead::Schema::Result::DataGatherer;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("data_gatherer");

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
    "claimed",
    {   data_type => "boolean",
        default_value => 0,
        is_nullable => 0,
    },
    "held",
    {   data_type => "boolean",
        default_value => 0,
        is_nullable => 0,
    },
    "complete",
    {   data_type => "boolean",
        default_value => 0,
        is_nullable => 0,
    },
    "action",
    { data_type => "character varying", is_nullable => 0, size => 50 },
    "datetime_created",
    {   data_type   => "timestamp",
        is_nullable => 0,
    },
    "datetime_updated",
    {   data_type   => "timestamp",
        is_nullable => 0,
    },
    "message",
    { data_type => "character varying", is_nullable => 0, size => 255, default_value => '' },
    "json",
    { data_type => "text", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(
        fields => ['claimed', 'held', 'complete', 'action', 'datetime_created'],
    );
}

__PACKAGE__->belongs_to(
    "user_account", "TauHead::Schema::Result::UserAccount",
    { id            => "user_account_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
