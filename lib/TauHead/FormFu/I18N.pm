use strict;

package TauHead::FormFu::I18N;

use Moose;
use TauHead::Util qw( camel2words );

*loc = \&localize;

sub localize {
    my $self = shift;

    return camel2words(@_);
}

sub get_handle {
    return shift->new;
}

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
