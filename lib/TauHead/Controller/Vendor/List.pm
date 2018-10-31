package TauHead::Controller::Vendor::List;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub list : Path('/vendor/list') : Args(0) {
    my ( $self, $c ) = @_;

    my $model = $c->model('DB');

    $c->stash->{areas} = $model->resultset('Area')->search(
        {
            'vendors.id' => { '!=' => undef },
        },
        {
            join => 'vendors',
            prefetch => [
                { station => 'system' },
                'parent_area',
            ],
            order_by => [
                'system.sort_order',
                'system.slug',
                'station.sort_order',
                'station.slug',
                'me.sort_order',
                'me.slug',
            ],
        }
    );

    return;
}

__PACKAGE__->meta->make_immutable;

1;
