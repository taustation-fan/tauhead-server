use utf8;

package TauHead::Schema::Result::System;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("system");

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        extra             => { unsigned => 1 },
        is_auto_increment => 1,
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
    "description",
    { data_type => "mediumtext", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraints(
    "name", ["name"],
    "slug", ["slug"],
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(name => 'sortorderx', fields => ['sort_order']);
}

__PACKAGE__->has_many(
    "stations",
    "TauHead::Schema::Result::Station",
    { "foreign.system_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

sub stations_sorted {
    my ($self) = @_;

    return $self->search_related(
        'stations',
        undef,
        {
            order_by => ['sort_order', 'slug'],
        },
    );
}

sub build_uri {
    my ( $self, $c ) = @_;

    return $c->uri_for(
        '/system',
        $self->slug,
    );
}

1;
