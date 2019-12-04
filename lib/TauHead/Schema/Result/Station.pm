use utf8;

package TauHead::Schema::Result::Station;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("station");

__PACKAGE__->add_columns(
    "slug",
    { data_type => "character varying", is_nullable => 0, size => 128 },
    "system_slug",
    { data_type => "character varying", is_nullable => 0, size => 128 },
    "sort_order",
    {   data_type         => "integer",
        is_nullable       => 0,
    },
    "name",
    { data_type => "character varying", is_nullable => 0, size => 128 },
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
        is_nullable       => 0,
    },
    "has_open_ruins_sewers",
    { data_type => "boolean", is_nullable => 0, default_value => 0 },
    "govt_center_has_daily_rations",
    { data_type => "boolean", is_nullable => 0, default_value => 1 },
    "has_public_shuttles",
    { data_type => "boolean", is_nullable => 0, default_value => 1 },
);

__PACKAGE__->set_primary_key("slug");

__PACKAGE__->add_unique_constraints(
    ["name"],
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(fields => ['system_slug']);
    $sqlt_table->add_index(fields => ['slug', 'system_slug', 'sort_order']);
}

__PACKAGE__->belongs_to(
    "system", "TauHead::Schema::Result::System",
    { slug          => "system_slug" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->has_many(
    "areas",
    "TauHead::Schema::Result::Area",
    { "foreign.station_slug" => "self.slug" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
    "interstellar_links",
    "TauHead::Schema::Result::InterstellarLink",
    [
        { "foreign.station_a" => "self.slug" },
        { "foreign.station_b" => "self.slug" },
    ]
);

__PACKAGE__->has_many(
    "action_counts",
    "TauHead::Schema::Result::StationActionCount",
    { "foreign.station_slug" => "self.slug" },
    { cascade_copy           => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
    "loot_counts",
    "TauHead::Schema::Result::StationLootCount",
    { "foreign.station_slug" => "self.slug" },
    { cascade_copy           => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
    "l4t_campaigns",
    "TauHead::Schema::Result::StationL4TCampaign",
    { "foreign.station_slug" => "self.slug" },
    { cascade_copy           => 0, cascade_delete => 0 },
);

sub interstellar_destinations {
    my ( $self ) = @_;

    my $slug = $self->slug;
    my @dest;

    for my $link ( $self->interstellar_links ) {
        if ( $slug eq $link->station_a ) {
            push @dest, $link->exit;
        }
        else {
            push @dest, $link->entry;
        }
    }

    return [ sort { $a->slug cmp $b->slug } @dest ];
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
