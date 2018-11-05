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
    {   data_type      => "decimal",
        size           => [ 12, 2 ],
        is_nullable    => 0,
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

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(name => 'last_seen_datetimex', fields => ['last_seen_datetime']);
}

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

    my $up = $price / $quantity;

    return sprintf "%.2f", $up;
}

sub unit_price_simple {
    my ( $self ) = @_;

    my $quantity = $self->quantity;
    my $price    = $self->price;

    my $up = $price / $quantity;

    if ( sprintf("%.2f", $up) == floor($up) ) {
        return floor($up);
    }

    return sprintf "%.2f", $up;
}

sub price_simple {
    my ( $self ) = @_;
    # If there are no decimal places, return an integer

    my $price = $self->price;

    if ( sprintf("%.2f", $price) == floor($price) ) {
        return floor($price);
    }

    return sprintf "%.2f", $price;
}

1;
