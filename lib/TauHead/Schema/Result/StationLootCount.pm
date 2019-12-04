use utf8;

package TauHead::Schema::Result::StationLootCount;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("station_loot_count");

__PACKAGE__->add_columns(
    "station_slug",
    {   data_type      => "varchar",
        size           => 128,
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "action",
    {   data_type   => "varchar",
        is_nullable => 0,
        size        => 50,
    },
    "item_slug",
    {   data_type      => "varchar",
        size           => 128,
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "player_level",
    {   data_type   => "integer",
        is_nullable => 0,
    },
    "count",
    {   data_type   => "integer",
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key("station_slug", "action", "item_slug", "player_level");

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(name => 'station_slug_action', fields => ['station_slug', 'action']);
}

__PACKAGE__->belongs_to(
    "station", "TauHead::Schema::Result::Station",
    { slug          => "station_slug" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->belongs_to(
    "item", "TauHead::Schema::Result::Item",
    { slug          => "item_slug" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
