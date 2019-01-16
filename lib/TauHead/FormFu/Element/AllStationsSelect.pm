package TauHead::FormFu::Element::AllStationsSelect;
use Moose;

extends 'HTML::FormFu::Element::Select';

has 'ignore_self_from_stash' => (
    is => 'rw',
);

after BUILD => sub {
    my $self = shift;

    my $rs = $self->form->stash->{context}->model('DB')->resultset('Station');

    my %cond;
    my @options;

    if ( $self->ignore_self_from_stash ) {
        my $ignore = $self->form->stash->{c}->stash->{station};

        if ($ignore) {
            $cond{'me.slug'} = { '!=' => $ignore->slug };
        }
    }

    my $station_rs = $rs->search(
      \%cond,
      {
        prefetch => 'system',
        order_by => [
            'system.sort_order',
            'me.sort_order',
        ],
      },
    );

    for my $station ( $station_rs->all ) {
      my $system  = $station->system;

      push @options, [
        $station->slug,
        sprintf( "%s, %s", $station->name, $system->name ),
      ];
    };

    $self->options(\@options);

    return;
};

__PACKAGE__->meta->make_immutable;

1;
