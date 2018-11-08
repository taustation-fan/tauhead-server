package TauHead::Controller::Stations_By_Area;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub stations_by_area :Path('/stations-by-area') : Args(0) : FormConfig {
}

sub stations_by_area_FORM_VALID {
    my ( $self, $c ) = @_;

    my $form = $c->stash->{form};
    $c->stash->{query_with} = $form->param_value('with');
    $c->stash->{query_area} = $form->param_value('area');

    my $model = $c->model('DB');

    $c->stash->{systems} = $model->resultset('System')->search(
        undef,
        {
            order_by => ['sort_order', 'slug'],
        },
    );

    return;
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
