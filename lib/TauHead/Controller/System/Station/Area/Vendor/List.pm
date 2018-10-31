package TauHead::Controller::System::Station::Area::Vendor::List;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub list : PathPart('vendor/list') : Chained('../../area') : Args(0) {
    my ( $self, $c ) = @_;

    my $area = $c->stash->{area};

    $c->stash->{vendors} = $area->vendors_sorted;

    return;
}

__PACKAGE__->meta->make_immutable;

1;
