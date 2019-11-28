use utf8;

package TauHead::Schema::Result::Session;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("session");

__PACKAGE__->add_columns(
    "id", { data_type => "char", is_nullable => 0, size => 72 },
    "session_data", { data_type => "mediumtext", size => 16777216, is_nullable => 0, default_value => '' },
    "expires",      { data_type => "integer", is_nullable => 0, default_value => '' },
);

__PACKAGE__->set_primary_key("id");

1;
