use utf8;

package TauHead::Schema::Result::Station;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("station");

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        extra             => { unsigned => 1 },
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "system_id",
    {   data_type         => "integer",
        extra             => { unsigned => 1 },
        is_nullable       => 0,
    },
    "sort_order",
    {   data_type         => "integer",
        extra             => { unsigned => 1 },
        is_nullable       => 0,
    },
    "name",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "slug",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "affiliation",
    {   data_type         => "enum",
        extra             => { list => [qw( consortium gaule freebooter independent )] },
        is_nullable       => 0,
    },
    "law_level",
    {   data_type         => "enum",
        extra             => { list => [qw( low medium high )] },
        is_nullable       => 0,
    },
    "orwellian_level",
    {   data_type         => "enum",
        extra             => { list => [qw( low medium high )] },
        is_nullable       => 0,
    },
    "level",
    {   data_type         => "integer",
        extra             => { unsigned => 1 },
        is_nullable       => 0,
    },
    "has_open_ruins_sewers",
    { data_type => "boolean", is_nullable => 0, default_value => 0 },
    "govt_center_has_daily_rations",
    { data_type => "boolean", is_nullable => 0, default_value => 1 },
    "description",
    { data_type => "mediumtext", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraints(
    "system_id_name", ["system_id", "name"],
    "system_id_slug", ["system_id", "slug"],
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(name => 'system_idx', fields => ['system_id']);
    $sqlt_table->add_index(name => 'slugx', fields => ['slug']);
    $sqlt_table->add_index(name => 'id_system_id_sort_orderx', fields => ['id', 'system_id', 'sort_order']);
}

__PACKAGE__->belongs_to(
    "system", "TauHead::Schema::Result::System",
    { id            => "system_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->has_many(
    "areas",
    "TauHead::Schema::Result::Area",
    { "foreign.station_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

# direct children - not sub-areas
sub child_areas_sorted {
    my ($self) = @_;

    return $self->search_related(
        'areas',
        {
            parent_area_id => undef,
        },
        {
            order_by => ['sort_order', 'slug'],
        },
    );
}

sub build_uri {
    my ( $self, $c ) = @_;

    my $system = $self->system;

    return $c->uri_for(
        '/system',
        $system->slug,
        'station',
        $self->slug,
    );
}

1;
