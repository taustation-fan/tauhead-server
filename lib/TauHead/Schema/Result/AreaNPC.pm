use utf8;

package TauHead::Schema::Result::AreaNPC;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("area_npc");

__PACKAGE__->add_columns(
    "area_id",
    {   data_type      => "integer",
        extra          => { unsigned => 1 },
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "npc_id",
    {   data_type         => "integer",
        extra             => { unsigned => 1 },
        is_foreign_key    => 1,
        is_nullable       => 0,
    },
);

__PACKAGE__->set_primary_key("area_id", "npc_id");

__PACKAGE__->belongs_to(
    "area", "TauHead::Schema::Result::Area",
    { id            => "area_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->belongs_to(
    "npc", "TauHead::Schema::Result::NPC",
    { id            => "npc_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
