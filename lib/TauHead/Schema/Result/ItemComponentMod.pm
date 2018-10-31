use utf8;

package TauHead::Schema::Result::ItemComponentMod;

use Moose;

extends 'DBIx::Class::Core';
with 'TauHead::Schema::Role';

__PACKAGE__->table("item_component_mod");

__PACKAGE__->add_columns(
    "item_slug",
    {
        data_type => "varchar",
        is_nullable => 0,
        size => 128,
        extra => {
            th_export => 1,
        },
    },
    "focus_mod",
    {   data_type   => "decimal",
        size        => [ 8, 3 ],
        is_nullable => 1,
        extra => {
            th_api_update => 1,
            th_display => 1,
            th_display_ignore_false => 1,
            th_export => 1,
        },
    },
    "strength_mod",
    {   data_type   => "decimal",
        size        => [ 8, 3 ],
        is_nullable => 1,
        extra => {
            th_api_update => 1,
            th_display => 1,
            th_display_ignore_false => 1,
            th_export => 1,
        },
    },
    "agility_mod",
    {   data_type   => "decimal",
        size        => [ 8, 3 ],
        is_nullable => 1,
        extra => {
            th_api_update => 1,
            th_display => 1,
            th_display_ignore_false => 1,
            th_export => 1,
        },
    },
    "stamina_mod",
    {   data_type   => "decimal",
        size        => [ 8, 3 ],
        is_nullable => 1,
        extra => {
            th_api_update => 1,
            th_display => 1,
            th_display_ignore_false => 1,
            th_export => 1,
        },
    },
    "intelligence_mod",
    {   data_type   => "decimal",
        size        => [ 8, 3 ],
        is_nullable => 1,
        extra => {
            th_api_update => 1,
            th_display => 1,
            th_display_ignore_false => 1,
            th_export => 1,
        },
    },
    "social_mod",
    {   data_type   => "decimal",
        size        => [ 8, 3 ],
        is_nullable => 1,
        extra => {
            th_api_update => 1,
            th_display => 1,
            th_display_ignore_false => 1,
            th_export => 1,
        },
    },
    "mod_type",
    {   data_type => "varchar",
        is_nullable => 0,
        size => 128,
        extra => {
            th_api_update => 1,
            th_display => 1,
            th_export => 1,
        },
    },
);

__PACKAGE__->set_primary_key("item_slug");

__PACKAGE__->belongs_to(
    "item", "TauHead::Schema::Result::Item",
    { slug          => "item_slug" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
