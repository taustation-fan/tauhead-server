use utf8;

package TauHead::Schema::Result::Preference;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(
    'InflateColumn::Serializer',
);

__PACKAGE__->table("preference");

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "name",
    { data_type => "character varying", is_nullable => 0, size => 128 },
    "display_label",
    { data_type => "character varying", is_nullable => 0, size => 128 },
    "description",
    { data_type => "text", is_nullable => 0 },
    "data_type",
    { data_type => "character varying", is_nullable => 0, size => 255  },
    "default_value",
    { data_type => "character varying", is_nullable => 1, size => 255 },
    "valid_values",
    {   data_type        => "text",
        is_nullable      => 0,
        serializer_class => 'JSON',
    },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraints(
    "name", ["name"],
    "display_label", ["display_label"],
);

__PACKAGE__->has_many(
    "user_preferencess",
    "TauHead::Schema::Result::UserAccountPreference",
    { "foreign.preference_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many( "users", "user_preferences", "preference", );

1;
