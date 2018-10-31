package TauHead::Controller::Mission::List;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub list : Path('/mission/list') : Args(0) {
    my ( $self, $c ) = @_;

    my $model = $c->model('DB');

    $c->stash->{missions} = $model->resultset('Mission')->search(
        undef,
        {
            order_by => ['name'],
        },
    );

    return;
}

__PACKAGE__->meta->make_immutable;

1;
