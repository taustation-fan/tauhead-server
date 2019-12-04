use utf8;

package TauHead::Schema::Result::VendorItem;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("vendor_item");

__PACKAGE__->add_columns(
    "id", # in-game `market_stall_item_id`
    {   data_type         => "integer",
        is_nullable       => 0,
    },
    "item_slug",
    {
        data_type => "character varying",
        is_nullable => 0,
        size => 128,
        extra => {
            th_export => 1,
        },
    },
    "vendor_id",
    {   data_type         => "integer",
        is_nullable       => 0,
    },

    "max_quantity_that_can_be_sold_per_attempt",
    { data_type => "integer", is_nullable => 0 },
    "default_quantity",
    { data_type => "integer", is_nullable => 0 },

    "has_unlimited_quantity",
    { data_type => "boolean", is_nullable => 0, default_value => 0 },

    "price",
    {   data_type   => "decimal",
        size        => [ 12, 2 ],
        is_nullable => 0,
    },

    "price_unit",
    {   data_type         => "enum",
        extra             => { list => [qw( credits bonds )] },
        is_nullable       => 0,
    },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint( "item_slug_vendor_idx", ["item_slug", "vendor_id"] );

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(fields => ['vendor_id']);
}

__PACKAGE__->belongs_to(
    "item", "TauHead::Schema::Result::Item",
    { slug          => "item_slug" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->belongs_to(
    "vendor", "TauHead::Schema::Result::Vendor",
    { id            => "vendor_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
