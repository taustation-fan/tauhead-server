use utf8;

package TauHead::Schema::Result::Vendor;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("vendor");

__PACKAGE__->add_columns(
    "id", # in-game `market_stall_id`
    {   data_type         => "integer",
        extra             => { unsigned => 1 },
        is_nullable       => 0,
    },
    "area_id",
    {   data_type         => "integer",
        extra             => { unsigned => 1 },
        is_nullable       => 0,
    },
    "name",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "slug",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "is_corporation",
    { data_type => "boolean", is_nullable => 0, default_value => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraints(
    "area_id_name", ["area_id", "name"],
    "area_id_slug", ["area_id", "slug"],
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(name => 'area_idx', fields => ['area_id']);
}

__PACKAGE__->belongs_to(
    "area", "TauHead::Schema::Result::Area",
    { "foreign.id" => "self.area_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->has_many(
    "vendor_items",
    "TauHead::Schema::Result::VendorItem",
    { "foreign.vendor_id" => "self.id" },
    { cascade_copy        => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many( "items", "vendor_items", "item", );

sub build_uri {
    my ( $self, $c ) = @_;

    my $area    = $self->area;
    my $station = $area->station;
    my $system  = $station->system;

    return $c->uri_for(
        '/system',
        $system->slug,
        'station',
        $station->slug,
        'area',
        $area->slug,
        'vendor',
        $self->slug,
    );
}

1;
