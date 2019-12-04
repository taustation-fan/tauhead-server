use utf8;

package TauHead::Schema::Result::ItemComponentWeapon;

use Moose;

extends 'DBIx::Class::Core';
with 'TauHead::Schema::Role';

__PACKAGE__->table("item_component_weapon");

__PACKAGE__->add_columns(
    "item_slug",
    {
        data_type => "character varying",
        is_nullable => 0,
        size => 128,
        extra => {
            th_export => 1,
        },
    },
    "energy_damage",
    {   data_type   => "decimal",
        size        => [ 8, 3 ],
        is_nullable => 0,
        extra => {
            th_api_update => 1,
            th_display => 1,
            th_display_ignore_false => 1,
            th_export => 1,
            json_export => 1,
        },
    },
    "impact_damage",
    {   data_type   => "decimal",
        size        => [ 8, 3 ],
        is_nullable => 0,
        extra => {
            th_api_update => 1,
            th_display => 1,
            th_display_ignore_false => 1,
            th_export => 1,
            json_export => 1,
        },
    },
    "piercing_damage",
    {   data_type   => "decimal",
        size        => [ 8, 3 ],
        is_nullable => 0,
        extra => {
            th_api_update => 1,
            th_display => 1,
            th_display_ignore_false => 1,
            th_export => 1,
            json_export => 1,
        },
    },
    "accuracy",
    {   data_type   => "decimal",
        size        => [ 8, 3 ],
        is_nullable => 0,
        extra => {
            th_api_update => 1,
            th_display => 1,
            th_display_ignore_false => 1,
            th_export => 1,
            json_export => 1,
        },
    },
    "hand_to_hand",
    {   data_type => "boolean",
        is_nullable => 0,
        default_value => 0,
        extra => {
            th_api_update => 1,
            th_display => 1,
            th_export => 1,
            json_export => 1,
        },
    },
    "is_long_range",
    {   data_type => "boolean",
        is_nullable => 0,
        default_value => 0,
        extra => {
            th_api_update => 1,
            th_display => 1,
            th_export => 1,
            json_export => 1,
        },
    },
    "weapon_type",
    {   data_type => "character varying",
        is_nullable => 0,
        extra => {
            th_api_update => 1,
            th_display => 1,
            th_export => 1,
            json_export => 1,
        },
    },
);

__PACKAGE__->set_primary_key("item_slug");

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(name => 'e_i_p_idx', fields => ['energy_damage', 'impact_damage', 'piercing_damage']);
}

__PACKAGE__->belongs_to(
    "item", "TauHead::Schema::Result::Item",
    { slug          => "item_slug" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
