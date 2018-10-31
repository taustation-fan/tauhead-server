use utf8;

package TauHead::Schema::Result::Log;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(
    'InflateColumn::DateTime',
    'InflateColumn::Serializer',
);

__PACKAGE__->table("log");

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        extra             => { unsigned => 1 },
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "user_id",
    {   data_type      => "integer",
        extra          => { unsigned => 1 },
        is_foreign_key => 1,
        is_nullable    => 1,
    },
    "datetime",
    {   data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 0,
    },
    "ip_address",
    { data_type => "varchar", is_nullable => 0, size => 255 },
    "action",
    { data_type => "varchar", is_nullable => 0, size => 255 },
    "data",
    {   data_type => "text",
        is_nullable => 1,
        serializer_class => 'JSON',
    },
    "owner_id",
    {   data_type      => "integer",
        extra          => { unsigned => 1 },
        is_foreign_key => 1,
        is_nullable    => 1,
    },
    "guid",
    { data_type => "varchar", is_nullable => 1, size => 128 },
);

__PACKAGE__->set_primary_key("id");

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(name => 'user_id_datetime', fields => ['user_id', 'datetime']);
}

__PACKAGE__->belongs_to(
    "user", "TauHead::Schema::Result::User",
    { "foreign.id" => "self.user_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE", join_type => 'left' },
);

__PACKAGE__->belongs_to(
    "owner", "TauHead::Schema::Result::User",
    { "foreign.id" => "self.owner_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE", join_type => 'left' },
);

1;
