use utf8;

package TauHead::Schema::Result::NPC;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("npc");

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "name",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "slug",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "primary_weapon_slug",
    { data_type => "varchar", is_nullable => 1, size => 128 },
    "armor_slug",
    { data_type => "varchar", is_nullable => 1, size => 128 },
    "avatar",
    { data_type => "varchar", is_nullable => 0, size => 128, default_value => "default" },
    "genotype",
    {   data_type   => "enum",
        is_nullable => 1,
        extra       => { list => [qw( baseline belter colonist harsene mall patrician )] },
    },
    "description",
    { data_type => "text", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraints(
    "slug", ["slug"],
);

__PACKAGE__->has_many(
    "area_npcs",
    "TauHead::Schema::Result::AreaNPC",
    { "foreign.npc_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many( "areas", "area_npcs", "area", );

__PACKAGE__->has_many(
    "mission_npcs",
    "TauHead::Schema::Result::MissionNPC",
    { "foreign.npc_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many( "missions", "mission_npcs", "mission", );

__PACKAGE__->belongs_to(
    "primary_weapon",
    "TauHead::Schema::Result::Item",
    { "foreign.slug" => "self.primary_weapon_slug" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->belongs_to(
    "armor",
    "TauHead::Schema::Result::Item",
    { "foreign.slug" => "self.armor_slug" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

sub build_uri {
    my ( $self, $c ) = @_;

    return $c->uri_for(
        '/npc',
        $self->slug,
    );
}

1;
