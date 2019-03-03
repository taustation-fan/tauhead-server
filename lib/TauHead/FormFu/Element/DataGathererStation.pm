package TauHead::FormFu::Element::DataGathererStation;
use Moose;

extends 'HTML::FormFu::Element::Text';

after BUILD => sub {
    my $self = shift;

    $self->name('current_station');

    $self->filter({
        type    => 'Regex',
        match   => ',.*',
        replace => '',
    });

    $self->constraints([
        'Required',
        'SingleValue',
    ]);

    $self->inflator({
        type => 'Callback',
        callback => sub {
            my $name = shift
                or die  "No value";
            my $station = $self->form->stash->{context}->model('DB')->resultset('Station')->find({
                name => $name,
            }) or die "Station not found";
            return $station;
        },
    });

    return;
};

__PACKAGE__->meta->make_immutable;

1;
