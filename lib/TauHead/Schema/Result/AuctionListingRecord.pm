use utf8;

package TauHead::Schema::Result::AuctionListingRecord;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(
    'InflateColumn::DateTime',
);

__PACKAGE__->table("auction_listing_record");

__PACKAGE__->add_columns(
    "auction_id",
    { data_type => "character varying", is_nullable => 0, size => 50 },
    "gct",
    { data_type => "character varying", is_nullable => 0, size => 17 },
    "datetime",
    {   data_type   => "timestamp",
        is_nullable => 0,
    },
    "user_account_id",
    {   data_type      => "integer",
        is_foreign_key => 1,
        is_nullable    => 0,
    },
);

__PACKAGE__->set_primary_key("auction_id", "gct", "user_account_id");

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(fields => ['auction_id', 'datetime']);
}

__PACKAGE__->belongs_to(
    "auction_listing", "TauHead::Schema::Result::AuctionListing",
    { "foreign.auction_id" => "self.auction_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE", join_type => 'left' },
);

__PACKAGE__->belongs_to(
    "user_account", "TauHead::Schema::Result::UserAccount",
    { "foreign.id" => "self.user_account_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE", join_type => 'left' },
);

1;
