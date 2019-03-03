package TauHead::Controller::System::Station;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub station : Chained('../system') : CaptureArgs(1) {
    my ( $self, $c, $slug ) = @_;

    my $system = $c->stash->{system};

    my $station = $c->model('DB')->resultset('Station')->find( { system_slug => $system->slug, slug => $slug } )
        or return $self->not_found($c);

    $self->add_breadcrumb( $c, [ $c->uri_for( '/system', $system->slug, 'station', $station->slug ), $station->name ] );

    $c->stash->{station} = $station;
}

sub view : PathPart('') : Chained('station') : Args(0) {
    my ( $self, $c ) = @_;

    my $system  = $c->stash->{system};
    my $station = $c->stash->{station};

    $c->stash->{areas} = $station->child_areas_sorted;

    $c->stash->{area_missions} = $c->model('DB')->resultset('Mission')->search(
        {
            'station.slug' => $station->slug,
        },
        {
            join => [
                { 'mission_areas' => { 'area' => 'station' } },
            ],
            distinct => 1,
            order_by => 'me.slug',
        }
    );

    $c->stash->{disqus_url} = $c->uri_for( '/system', $system->slug, 'station', $station->slug );
}

sub loot : PathPart('loot') : Chained('station') : Args(0) {
    my ( $self, $c ) = @_;

    my $station = $c->stash->{station};

    # wrecks_salvage_loot
    my $action_count = $station->search_related(
        'action_counts',
        {
            action => 'wrecks_salvage_loot',
        },
        {
            '+select' => [{ sum => 'count', -as => 'sum_count' }],
            '+as'     => ['sum_count'],
            rows      => 1,
        },
    )->first;

    if ( $action_count && $action_count->count ) {
        $action_count = $action_count->get_column('sum_count');

        my $records_rs = $station->search_related(
            'loot_counts',
            {
                action => 'wrecks_salvage_loot',
            },
            {
                '+select' => [{ sum => 'count' }],
                '+as'     => ['sum_count'],
                group_by  => ['item_slug'],
                prefetch  => 'item',
                order_by  => 'me.sum_count DESC',
            }
        );

        my @result;
        my $loot_count = 0;

        while ( my $record = $records_rs->next ) {
            my $percent = $record->get_column('sum_count') / $action_count * 100;
            $percent = sprintf "%.1f", $percent;

            push @result, {
                loot_count => $record,
                item       => $record->item,
                percent    => $percent,
            };

            $loot_count++;
        }

        my $loot_nothing    = $action_count - $loot_count;
        my $nothing_percent = sprintf "%.1f", ( $loot_nothing / $action_count * 100 );

        $c->stash->{wrecks_salvage_loot}                 = \@result;
        $c->stash->{wrecks_salvage_loot_nothing}         = $loot_nothing;
        $c->stash->{wrecks_salvage_loot_nothing_percent} = $nothing_percent;
        $c->stash->{wrecks_salvage_loot_action_count}    = $action_count;
    };
}

sub end : ActionClass('RenderView') { }

__PACKAGE__->meta->make_immutable;

1;
