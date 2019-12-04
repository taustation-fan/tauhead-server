use utf8;

package TauHead::Schema::Result::ItemComponentArmor;
use Moose;

extends 'DBIx::Class::Core';
with 'TauHead::Schema::Role';

__PACKAGE__->table("item_component_armor");

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
    "energy",
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
    "impact",
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
    "piercing",
    {   data_type   => "decimal",
        size        => [ 8, 3 ],
        is_nullable => 0,,
        extra => {
            th_api_update => 1,
            th_display => 1,
            th_display_ignore_false => 1,
            th_export => 1,
            json_export => 1,
        },
    },
);

__PACKAGE__->set_primary_key("item_slug");

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(fields => ['energy', 'impact', 'piercing']);
}

__PACKAGE__->belongs_to(
    "item", "TauHead::Schema::Result::Item",
    { slug          => "item_slug" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
