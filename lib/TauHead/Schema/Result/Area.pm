use utf8;

package TauHead::Schema::Result::Area;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("area");

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "station_slug",
    {   data_type      => "character varying",
        size           => 128,
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "parent_area_id",
    {   data_type         => "integer",
        is_foreign_key => 1,
        is_nullable       => 1,
    },
    "sort_order",
    {   data_type         => "integer",
        is_nullable       => 0,
    },
    "name",
    { data_type => "character varying", is_nullable => 0, size => 128 },
    "aka",
    { data_type => "character varying", is_nullable => 0, size => 128 },
    "slug",
    { data_type => "character varying", is_nullable => 0, size => 128 },
    "bg_img",
    { data_type => "character varying", is_nullable => 1, size => 256 },
    "content_img",
    { data_type => "character varying", is_nullable => 1, size => 256 },
    "content_side_img",
    { data_type => "character varying", is_nullable => 1, size => 256 },
    "hero_img",
    { data_type => "character varying", is_nullable => 1, size => 256 },
    "other_img",
    { data_type => "character varying", is_nullable => 1, size => 256 },
    "area_description_short",
    { data_type => "text", is_nullable => 1 },
    "area_description_long",
    { data_type => "text", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraints(
    "station_slug_name", ["station_slug", "name"],
    "station_slug_slug", ["station_slug", "slug"],
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(name => 'station_slugx', fields => ['station_slug']);
    $sqlt_table->add_index(name => 'id_station_slug_sort_orderx', fields => ['id', 'station_slug', 'sort_order']);
}

__PACKAGE__->belongs_to(
    "station", "TauHead::Schema::Result::Station",
    { slug          => "station_slug" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->belongs_to(
    "parent_area",
    "TauHead::Schema::Result::Area",
    { "foreign.id" => "self.parent_area_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->has_many(
    "child_areas",
    "TauHead::Schema::Result::Area",
    { "foreign.parent_area_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
    "vendors",
    "TauHead::Schema::Result::Vendor",
    { "foreign.area_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
    "area_npcs",
    "TauHead::Schema::Result::AreaNPC",
    { "foreign.area_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many( "npcs", "area_npcs", "npc", );

__PACKAGE__->has_many(
    "mission_areas",
    "TauHead::Schema::Result::MissionArea",
    { "foreign.area_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many( "missions", "mission_areas", "mission", );

sub child_areas_sorted {
    my ($self) = @_;

    return $self->search_related(
        'child_areas',
        undef,
        {
            order_by => ['sort_order', 'slug'],
        },
    );
}

sub missions_sorted {
    my ($self) = @_;

    return $self->missions->search(
        undef,
        {
            order_by => ['name', 'slug'],
        },
    );
}

sub npcs_sorted {
    my ($self) = @_;

    return $self->npcs->search(
        undef,
        {
            order_by => ['name', 'slug'],
        },
    );
}

sub vendors_sorted {
    my ($self) = @_;

    return $self->vendors->search(
        undef,
        {
            order_by => ['name', 'slug'],
        },
    );
}

sub build_uri {
    my ( $self, $c ) = @_;

    my $station = $self->station;
    my $system  = $station->system;

    return $c->uri_for(
        '/system',
        $system->slug,
        'station',
        $station->slug,
        'area',
        $self->slug,
    );
}

1;
