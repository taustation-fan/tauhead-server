package TauHead::Controller::System::List;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub list : Path('/system/list') : Args(0) {
    my ( $self, $c ) = @_;

    my $model = $c->model('DB');

    $c->stash->{systems} = $model->resultset('System')->search(
        undef,
        {
            order_by => ['sort_order', 'slug'],
        },
    );

    return;
}

__PACKAGE__->meta->make_immutable;

1;
