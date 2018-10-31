package TauHead::FormFu::Element::AllAreas;
use Moose;

extends 'HTML::FormFu::Element::Checkboxgroup';

after BUILD => sub {
    my $self = shift;

    my $rs = $self->form->stash->{context}->model('DB')->resultset('Area');

    my %sub;
    my @options;

    my $sub_rs = $rs->search(
      {
        parent_area_id => { '!=' => undef },
      },
    );

    for ( $sub_rs->all ) {
      push @{ $sub{ $_->parent_area_id } }, $_;
    }

    my $areas_rs = $rs->search(
      {
        parent_area_id => undef,
      },
      {
        prefetch => {'station', 'system'},
        order_by => [
            'system.sort_order',
            'station.sort_order',
        ],
      },
    );

    for my $area ( $areas_rs->all ) {
      my $station = $area->station;
      my $system  = $station->system;

      push @options, [
        $area->id,
        sprintf( "%s, %s, %s", $area->name, $station->name, $system->name ),
      ];

      if ( $sub{ $area->id } ) {
        for my $sub_area ( sort _sort_sub_areas @{ $sub{ $area->id } } ) {
          push @options, [
            $sub_area->id,
            sprintf( " - %s, %s, %s", $sub_area->name, $station->name, $system->name ),
          ]
        }
      }
    };

    $self->options(\@options);

    return;
};

sub _sort_sub_areas {
  return $a->sort_order <=> $b->sort_order || $a->slug cmp $b->slug;
}

__PACKAGE__->meta->make_immutable;

1;
