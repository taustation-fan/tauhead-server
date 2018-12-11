use utf8;

package TauHead::Schema::Result::ItemType;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("item_type");

__PACKAGE__->add_columns(
    "slug",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "name",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "sort_order",
    {   data_type         => "integer",
        extra             => { unsigned => 1 },
        is_nullable       => 0,
    },
);

__PACKAGE__->set_primary_key("slug");

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index(name => 'namex', fields => ['name']);
}

__PACKAGE__->has_many(
    "items",
    "TauHead::Schema::Result::Item",
    { "foreign.item_type_slug" => "self.slug" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

1;
