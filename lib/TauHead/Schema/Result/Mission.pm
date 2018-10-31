use utf8;

package TauHead::Schema::Result::Mission;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("mission");

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        extra             => { unsigned => 1 },
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "name",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "slug",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "level",
    {   data_type         => "integer",
        extra             => { unsigned => 1 },
        is_nullable       => 1,
    },
    "description",
    { data_type => "mediumtext", is_nullable => 0 },
    "mermaid",
    { data_type => "mediumtext", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
    "mission_areas",
    "TauHead::Schema::Result::MissionArea",
    { "foreign.mission_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many( "areas", "mission_areas", "area", );

__PACKAGE__->has_many(
    "mission_npcs",
    "TauHead::Schema::Result::MissionNPC",
    { "foreign.mission_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many( "npcs", "mission_npcs", "npc", );

sub npcs_sorted {
    my ($self) = @_;

    return $self->result_source->schema->resultset('MissionNPC')->search_related(
        'npc',
        {
            mission_id => $self->id,
        },
        {
            order_by => ['npc.name'],
        },
    );
}

sub build_uri {
    my ( $self, $c ) = @_;

    return $c->uri_for(
        '/mission',
        $self->slug,
    );
}

sub mermaid_graphs {
    my ( $self ) = @_;

    my $mermaid = $self->mermaid;

    return if !defined $mermaid || !length $mermaid;

    my @graphs = split m/(?<=\n)(?=graph\s+(?:TD|TB|BT|RL|LR)\b)/, $mermaid;

    return wantarray ? @graphs : [@graphs];
}

1;
