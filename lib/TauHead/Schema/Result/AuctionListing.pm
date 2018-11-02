use utf8;

package TauHead::Schema::Result::AuctionListing;

use strict;
use warnings;

use base 'DBIx::Class::Core';

use POSIX qw( floor );

__PACKAGE__->load_components(
    'InflateColumn::DateTime',
);

__PACKAGE__->table("auction_listing");

__PACKAGE__->add_columns(
    "auction_id",
    { data_type => "varchar", is_nullable => 0, size => 50 },
    "first_seen_gct",
    { data_type => "varchar", is_nullable => 0, size => 17 },
    "last_seen_gct",
    { data_type => "varchar", is_nullable => 0, size => 17 },
    "item_slug",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "quantity",
    {   data_type      => "integer",
        extra          => { unsigned => 1 },
        is_nullable    => 1,
    },
    "price",
    {   data_type      => "integer",
        extra          => { unsigned => 1 },
        is_nullable    => 1,
    },
    "seller_slug",
    { data_type => "varchar", is_nullable => 0, size => 255 },
    "seller_name",
    { data_type => "varchar", is_nullable => 0, size => 255 },
    "first_seen_datetime",
    {   data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 0,
    },
    "last_seen_datetime",
    {   data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 0,
    },
);

__PACKAGE__->set_primary_key("auction_id");

__PACKAGE__->has_many(
    "auction_listing_records",
    "TauHead::Schema::Result::AuctionListingRecord",
    { "foreign.auction_id" => "self.auction_id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

__PACKAGE__->belongs_to(
    "item", "TauHead::Schema::Result::Item",
    { "foreign.slug" => "self.item_slug" },
    { cascade_copy   => 0, cascade_delete => 0 },
);

sub unit_price {
    my ( $self ) = @_;

    my $quantity = $self->quantity;
    my $price    = $self->price;

    return $price if 1 == $quantity;

    return floor( $price/$quantity );
}

1;
