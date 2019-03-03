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
    "system_slug",
    { data_type => "varchar", is_nullable => 0, size => 128 },
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
    "has_public_shuttles",
    { data_type => "boolean", is_nullable => 0, default_value => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraints(
    "name", ["name"],
    "slug", ["slug"],
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(name => 'system_slugx', fields => ['system_slug']);
    $sqlt_table->add_index(name => 'id_system_slug_sort_orderx', fields => ['id', 'system_slug', 'sort_order']);
}

__PACKAGE__->belongs_to(
    "system", "TauHead::Schema::Result::System",
    { slug          => "system_slug" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->has_many(
    "areas",
    "TauHead::Schema::Result::Area",
    { "foreign.station_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
    "interstellar_links",
    "TauHead::Schema::Result::InterstellarLink",
    [
        { "foreign.station_a" => "self.id" },
        { "foreign.station_b" => "self.id" },
    ]
);

sub interstellar_destinations {
    my ( $self ) = @_;

    my $id = $self->id;
    my @dest;

    for my $link ( $self->interstellar_links ) {
        if ( $id == $link->station_a ) {
            push @dest, $link->exit;
        }
        else {
            push @dest, $link->entry;
        }
    }

    return [ sort { $a->id <=> $b->id } @dest ];
}

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
