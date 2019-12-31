package TauHead::Controller::Item;
use Moose;
use Cpanel::JSON::XS qw( encode_json );
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub item : Chained('/') : CaptureArgs(1) {
    my ( $self, $c, $slug ) = @_;

    my $item = $c->model('DB')->resultset('Item')->search(
        { slug => $slug },
        {
            prefetch => [ map { 'item_component_'.$_ } qw( armor medical mod weapon ) ],
        }
    )->first;

    return $self->not_found($c)
        if !$item;

    $c->stash->{item} = $item;
}

sub view : PathPart('') : Chained('item') : Args(0) {
    my ( $self, $c ) = @_;

    my $item = $c->stash->{item};

    if ( $c->request->accepts('application/json') )  {
        return $self->_view_json($c);
    }

    $c->stash->{disqus_url} = $c->uri_for( '/item', $item->slug );
}

sub _view_json {
    my ( $self, $c ) = @_;

    my $item = $c->stash->{item};

    my $out = $item->json_export_hashref;

    for my $rel_name (map { 'item_component_'.$_ } qw( armor medical mod weapon )) {
        if ( my $rel = $item->$rel_name ) {
            $out->{$rel_name} = $rel->json_export_hashref;
        }
    }

    $c->stash->{rest} = $out;
}

sub download : Path('/item/download') : Args(0) : FormConfig {
    my ( $self, $c ) = @_;

    $self->require_login($c);
}

sub download_FORM_NOT_VALID {
    my ( $self, $c ) = @_;

    $c->stash->{rest}
        = { errors => $c->stash->{form}->jquery_validation_errors_join('<br/>'),
        };
}

sub download_FORM_VALID {
    my ( $self, $c ) = @_;

    my $rs = $c->model('DB')->resultset('Item');
    my @items;

    while ( my $row = $rs->next ) {
        my %item;

        for my $cv ( @{ $row->export_col_vals } ) {
            $item{ $cv->{name} } = $cv->{value};
        }

        for my $comp (qw( armor medical mod weapon )) {
            my $method = "item_component_$comp";
            if ( my $rel = $row->$method ) {
                for my $cv ( @{ $rel->export_col_vals } ) {
                    $item{$method}{ $cv->{name} } = $cv->{value};
                }
            }
        }

        push @items, \%item;
    }

    $self->add_log( $c, 'item/download',
        {
            description => "Item list downloaded",
        },
    );

    $c->response->content_type('application/json');
    $c->response->header( 'Content-Disposition' => "attachment; filename=tauhead-items.json" );
    $c->response->body( encode_json({ items=> \@items }));
    $c->detach;
}

sub loot : PathPart('loot') : Chained('item') : Args(0) {
    my ( $self, $c ) = @_;

    my $item = $c->stash->{item};

    $self->add_breadcrumb( $c, [ $item->build_uri($c), $item->name ] );

    $self->_wrecks_salvage_loot($c);
    $self->_wrecks_l4t_loot($c);
    $self->_wrecks_sewers_loot($c);
}

sub _wrecks_salvage_loot {
    my ( $self, $c ) = @_;

    my $item = $c->stash->{item};

    my %cond = (
        action => 'wrecks_salvage_loot',
    );
    my %attrs = (
        '+select' => [{ sum => 'count', -as => 'sum_count' }],
        group_by  => ['station_slug', 'me.action', 'me.item_slug', 'me.player_level'],
        prefetch  => { station => 'system' },
        order_by  => ['me.sum_count DESC', 'station_slug'],
    );

    my $records_rs = $item->search_related(
        'loot_counts',
        \%cond,
    );

    if ( $records_rs->count ) {
        $c->stash->{wrecks_salvage_loot} = $item->search_related(
            'loot_counts',
            \%cond,
            \%attrs,
        );
    };
}

sub _wrecks_l4t_loot {
    my ( $self, $c ) = @_;

    my $item = $c->stash->{item};

    my %cond = (
        action => 'wrecks_looking_for_trouble_loot',
    );
    my %attrs = (
        '+select' => [{ sum => 'count', -as => 'sum_count' }],
        group_by  => ['station_slug', 'me.action', 'me.item_slug', 'me.player_level', 'me.count'],
        prefetch  => { station => 'system' },
        order_by  => ['me.sum_count DESC', 'station_slug'],
    );

    my $records_rs = $item->search_related(
        'loot_counts',
        \%cond,
    );

    if ( $records_rs->count ) {
        $c->stash->{wrecks_looking_for_trouble_loot} = $item->search_related(
            'loot_counts',
            \%cond,
            \%attrs,
        );
    };
}

sub _wrecks_sewers_loot {
    my ( $self, $c ) = @_;

    my $item = $c->stash->{item};

    my %cond = (
        action => 'wrecks_sewers_loot',
    );
    my %attrs = (
        '+select' => [{ sum => 'count', -as => 'sum_count' }],
        group_by  => ['station_slug', 'me.action', 'me.item_slug', 'me.player_level', 'me.count'],
        prefetch  => { station => 'system' },
        order_by  => ['me.sum_count DESC', 'station_slug'],
    );

    my $records_rs = $item->search_related(
        'loot_counts',
        \%cond,
    );

    if ( $records_rs->count ) {
        $c->stash->{wrecks_sewers_loot} = $item->search_related(
            'loot_counts',
            \%cond,
            \%attrs,
        );
    };
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
