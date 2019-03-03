use utf8;

package TauHead::Schema::Result::InterstellarLink;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("interstellar_link");

__PACKAGE__->add_columns(
    "station_a",
    {   data_type      => "varchar",
        size           => 128,
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "station_b",
    {   data_type      => "varchar",
        size           => 128,
        is_foreign_key => 1,
        is_nullable    => 0,
    },
);

__PACKAGE__->set_primary_key("station_a", "station_b");

__PACKAGE__->belongs_to(
    "entry", "TauHead::Schema::Result::Station",
    { slug          => "station_a" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->belongs_to(
    "exit", "TauHead::Schema::Result::Station",
    { slug          => "station_b" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
