use utf8;

package TauHead::Schema::Result::StationL4TCampaign;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("station_l4t_campaign");

__PACKAGE__->add_columns(
    "station_slug",
    {   data_type      => "character varying",
        size           => 128,
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "campaign_level",
    {   data_type   => "integer",
        is_nullable => 0,
    },
    "campaign_difficulty",
    {   data_type      => "character varying",
        size           => 20,
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

__PACKAGE__->set_primary_key("station_slug", "campaign_level", "campaign_difficulty", "player_level");

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(fields => ['station_slug', 'player_level']);
}

__PACKAGE__->belongs_to(
    "station", "TauHead::Schema::Result::Station",
    { slug          => "station_slug" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
