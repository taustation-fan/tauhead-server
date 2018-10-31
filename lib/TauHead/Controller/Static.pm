package TauHead::Controller::Static;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub privacy : Chained('/') : Args(0) {
}

__PACKAGE__->meta->make_immutable;

1;
