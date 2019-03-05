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

    $self->_wrecks_salvage_loot($c);
    $self->_wrecks_l4t_loot($c);
    $self->_wrecks_sewers_loot($c);
}

sub _wrecks_salvage_loot {
    my ( $self, $c ) = @_;

    my $station = $c->stash->{station};

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
            my $count = $record->get_column('sum_count');
            my $percent = $count / $action_count * 100;
            $percent = sprintf "%.1f", $percent;
            $loot_count += $count;

            push @result, {
                loot_count => $record,
                item       => $record->item,
                percent    => $percent,
            };
        }
        my $loot_nothing    = $action_count - $loot_count;
        my $nothing_percent = sprintf "%.1f", ( $loot_nothing / $action_count * 100 );

        $c->stash->{wrecks_salvage_loot}                 = \@result;
        $c->stash->{wrecks_salvage_loot_nothing}         = $loot_nothing;
        $c->stash->{wrecks_salvage_loot_nothing_percent} = $nothing_percent;
        $c->stash->{wrecks_salvage_loot_action_count}    = $action_count;
    };
}

sub _wrecks_l4t_loot {
    my ( $self, $c ) = @_;

    my $station = $c->stash->{station};

    my $action_count = $station->search_related(
        'action_counts',
        {
            action => 'wrecks_looking_for_trouble_loot',
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
                action => 'wrecks_looking_for_trouble_loot',
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

        while ( my $record = $records_rs->next ) {
            my $percent = $record->get_column('sum_count') / $action_count * 100;
            $percent = sprintf "%.1f", $percent;

            push @result, {
                loot_count => $record,
                item       => $record->item,
                percent    => $percent,
            };
        }

        $c->stash->{wrecks_looking_for_trouble_loot}                 = \@result;
        $c->stash->{wrecks_looking_for_trouble_loot_action_count}    = $action_count;
    };
}

sub _wrecks_sewers_loot {
    my ( $self, $c ) = @_;

    my $station = $c->stash->{station};

    my $action_count = $station->search_related(
        'action_counts',
        {
            action => 'wrecks_sewers_loot',
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
                action => 'wrecks_sewers_loot',
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

        while ( my $record = $records_rs->next ) {
            my $percent = $record->get_column('sum_count') / $action_count * 100;
            $percent = sprintf "%.1f", $percent;

            push @result, {
                loot_count => $record,
                item       => $record->item,
                percent    => $percent,
            };
        }

        $c->stash->{wrecks_sewers_loot}                 = \@result;
        $c->stash->{wrecks_sewers_loot_action_count}    = $action_count;
    };
}

sub player_level_l4t : PathPart('loot/by_player_level/looking_for_trouble') : Chained('station') : Args(0) {
    my ( $self, $c ) = @_;

    my $station = $c->stash->{station};
    my $model   = $c->model('DB');

    my $player_level_rs = $model->resultset('StationLootCount')->search(
        {
            action       => 'wrecks_looking_for_trouble_loot',
            station_slug => $station->slug,
        },
        {
            'select' => [
                'player_level',
                { sum => 'count', -as => 'sumx' },
            ],
            'as' => [
                'player_level',
                'sumx',
            ],
            group_by => 'player_level',
            order_by => 'player_level',
        },
    );

    return if ! $player_level_rs->count;

    my %total_count;
    my @heading;
    my @rows;
    my $level_i = 0;
    my $max_i   = 0;

    while ( my $level_rs = $player_level_rs->next ) {
        my $level       = $level_rs->get_column('player_level');
        my $total_count = $level_rs->get_column('sumx');

        $total_count{$level} = $total_count;
        $heading[$level_i]   = $level;

        my $level_loot_rs = $model->resultset('StationLootCount')->search(
            {
                action       => 'wrecks_looking_for_trouble_loot',
                station_slug => $station->slug,
                player_level => $level,
            },
            {
                '+select' => [{ sum => 'count', -as => 'sum_count' }],
                '+as'     => ['sum_count'],
                group_by  => 'item_slug',
                prefetch  => 'item',
                order_by  => ['me.sum_count DESC', 'item_slug'],
            }
        );
        my $row_i = 0;
        while ( my $record = $level_loot_rs->next ) {
            $max_i = $row_i if $row_i > $max_i;

            my $sum_count = $record->get_column('sum_count');
            my $percent = $sum_count / $total_count * 100;
            $percent = sprintf "%.1f", $percent;

            $rows[$row_i][$level_i] = {
                level      => $level,
                loot_count => $sum_count,
                item       => $record->item,
                percent    => $percent,
            };
            $row_i++;
        }
        $level_i++;
    }

    $c->stash->{total_count} = \%total_count;
    $c->stash->{col_count}   = [0 .. $max_i];
    $c->stash->{heading}     = \@heading;
    $c->stash->{rows}        = \@rows;
}

sub end : ActionClass('RenderView') { }

__PACKAGE__->meta->make_immutable;

1;
