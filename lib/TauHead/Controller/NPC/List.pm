package TauHead::Controller::NPC::List;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub list : Path('/npc/list') : Args(0) {
    my ( $self, $c ) = @_;

    my $model = $c->model('DB');

    $c->stash->{npcs} = $model->resultset('NPC')->search(
        undef,
        {
            order_by => ['name'],
        },
    );

    return;
}

__PACKAGE__->meta->make_immutable;

1;
