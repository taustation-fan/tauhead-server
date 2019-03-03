use utf8;

package TauHead::Schema::Result::StationActionCount;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("station_action_count");

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
    "player_level",
    {   data_type   => "integer",
        extra       => { unsigned => 1 },
        is_nullable => 0,
    },
    "count",
    {   data_type   => "integer",
        extra       => { unsigned => 1 },
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key("station_slug", "action", "player_level");

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(name => 'station_slug_action', fields => ['station_slug', 'action']);
}

__PACKAGE__->belongs_to(
    "station", "TauHead::Schema::Result::Station",
    { slug          => "station_slug" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
