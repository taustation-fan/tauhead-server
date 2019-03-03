use utf8;

package TauHead::Schema::Result::Item;
use Moose;

extends 'DBIx::Class::Core';
with 'TauHead::Schema::Role';

__PACKAGE__->table("item");

__PACKAGE__->add_columns(
    "item_type_slug",
    {
        data_type => "varchar",
        is_nullable => 0,
        size => 128,
        extra => {
            th_export => 1,
            json_export => 1,
        },
    },
    "name",
    {
        data_type => "varchar",
        is_nullable => 0,
        size => 128,
        extra => {
            th_export => 1,
            json_export => 1,
        },
    },
    "slug",
    {
        data_type => "varchar",
        is_nullable => 0,
        size => 128,
        extra => {
            th_export => 1,
            json_export => 1,
        },
    },
    "image",
    {
        data_type => "varchar",
        is_nullable => 0,
        size => 128,
        extra => {
            th_export => 1,
            json_export => 1,
        },
    },

    "tier",
    {
        data_type => "integer",
        is_nullable => 0,
        extra => {
            th_display => 1,
            th_export => 1,
            json_export => 1,
        },
    },

    "stack_size",
    {
        data_type => "integer",
        is_nullable => 0,
        extra => {
            th_display => 1,
            th_export => 1,
        },
    },

    "bonds",
    {
        data_type => "integer",
        is_nullable => 0,
        extra => {
            th_display => 1,
            th_display_ignore_false => 1,
            th_export => 1,
            json_export => 1,
        },
    },

    "mass",
    {   data_type   => "decimal",
        size        => [ 12, 2 ],
        is_nullable => 0,
        extra => {
            th_display => 1,
            th_export => 1,
            json_export => 1,
        },
    },

    "rarity",
    {   data_type         => "enum",
        is_nullable       => 0,
        extra => {
            list => [qw( common uncommon rare epic heirloom )],
            th_display => 1,
            th_export => 1,
            json_export => 1,
        },
    },

    "value",
    {   data_type   => "decimal",
        size        => [ 12, 2 ],
        is_nullable => 0,
        extra => {
            th_display => 1,
            th_export => 1,
            json_export => 1,
        },
    },

    "description",
    {
        data_type => "mediumtext",
        is_nullable => 0,
        extra => {
            th_export => 1,
        },
    },
);

__PACKAGE__->set_primary_key("slug");

__PACKAGE__->add_unique_constraints( namex => ["name"] );

__PACKAGE__->belongs_to(
    "item_type", "TauHead::Schema::Result::ItemType",
    { slug          => "item_type_slug" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->might_have(
    "item_component_armor",
    "TauHead::Schema::Result::ItemComponentArmor",
    { "foreign.item_slug" => "self.slug" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->might_have(
    "item_component_weapon",
    "TauHead::Schema::Result::ItemComponentWeapon",
    { "foreign.item_slug" => "self.slug" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->might_have(
    "item_component_medical",
    "TauHead::Schema::Result::ItemComponentMedical",
    { "foreign.item_slug" => "self.slug" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->might_have(
    "item_component_mod",
    "TauHead::Schema::Result::ItemComponentMod",
    { "foreign.item_slug" => "self.slug" },
    { cascade_copy      => 0, cascade_delete => 0 },
);


__PACKAGE__->has_many(
    "vendor_items",
    "TauHead::Schema::Result::VendorItem",
    { "foreign.item_slug" => "self.slug" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->might_have(
    "npc_with_primary_weapon",
    "TauHead::Schema::Result::NPC",
    { "foreign.primary_weapon_slug" => "self.slug" },
    { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->might_have(
    "npc_with_armor",
    "TauHead::Schema::Result::NPC",
    { "foreign.armor_slug" => "self.slug" },
    { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many( "vendors", "vendor_items", "vendor", );

__PACKAGE__->has_many(
    "auction_listings",
    "TauHead::Schema::Result::AuctionListing",
    { "foreign.item_slug" => "self.slug" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
    "loot_counts",
    "TauHead::Schema::Result::StationLootCount",
    { "foreign.item_slug" => "self.slug" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

sub item_component_names {
    return
        "item_component_armor",
        "item_component_medical",
        "item_component_mod",
        "item_component_weapon";
}

sub build_uri {
    my ( $self, $c ) = @_;

    return $c->uri_for(
        '/item',
        $self->slug,
    );
}

sub in_game_link {
    my ( $self, $c ) = @_;

    return join "/",
        $c->config->{game_server_domain},
        'item',
        $self->slug;
}

sub auction_listings_by_newest {
    my ($self) = @_;

    return $self->search_related(
        'auction_listings',
        undef,
        {
            order_by => ['first_seen_datetime DESC'],
        },
    );
}

1;
