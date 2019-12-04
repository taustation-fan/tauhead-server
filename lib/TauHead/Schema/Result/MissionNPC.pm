use utf8;

package TauHead::Schema::Result::MissionNPC;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("mission_npc");

__PACKAGE__->add_columns(
    "mission_id",
    {   data_type      => "integer",
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "npc_id",
    {   data_type         => "integer",
        is_foreign_key    => 1,
        is_nullable       => 0,
    },
);

__PACKAGE__->set_primary_key("mission_id", "npc_id");

__PACKAGE__->belongs_to(
    "mission", "TauHead::Schema::Result::Mission",
    { id            => "mission_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->belongs_to(
    "npc", "TauHead::Schema::Result::NPC",
    { id            => "npc_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
