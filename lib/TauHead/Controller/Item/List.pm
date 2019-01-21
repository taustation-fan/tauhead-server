package TauHead::Controller::Item::List;
use Moose;
use Try::Tiny;
use namespace::autoclean;

use TauHead::Util qw( html2text );

BEGIN { extends 'TauHead::BaseController' }

sub list : Path('') : Args(0) : FormConfig { }

sub list_FORM_NOT_SUBMITTED {
    my ( $self, $c ) = @_;

    # No problem - default all-items list
    return $self->_list( $c );
}

sub list_FORM_VALID {
    my ( $self, $c ) = @_;

    return $self->_list( $c );
}

sub _list {
    my ( $self, $c ) = @_;

    my $form = $c->stash->{form};
    my $item_type = $form->param_value('item_type');

    if ( $item_type ) {
        $item_type = $c->model('DB')->resultset('ItemType')->find({ slug => $item_type });
    }

    my $default_columns = [
        [ 'me.name'         => 'Name' ],
        [ 'me.tier'         => 'Tier' ],
        [ 'me.rarity'       => 'Rarity' ],
        [ 'vendor_items.id' => 'Vendor Sold' ],
        [ 'me.value'        => 'Value' ],
        [ 'me.mass'         => 'Mass' ],
    ];

    my %item_type_search = (
        armor => {
            join => 'item_component_armor',
            columns => [
                [ 'me.name'   => 'Name' ],
                [ 'me.tier'   => 'Tier' ],
                [ 'me.rarity' => 'Rarity' ],
                [ 'vendor_items.id' => 'Vendor Sold' ],
                [ 'item_component_armor.energy'   => 'Energy' ],
                [ 'item_component_armor.impact'   => 'Impact' ],
                [ 'item_component_armor.piercing' => 'Piercing' ],
                [ 'total_armor' => 'Total Armor', \'(item_component_armor.energy + item_component_armor.impact + item_component_armor.piercing) AS total_armor' ],
            ],
        },
        medical => {
            join => 'item_component_medical',
            columns => [
                [ 'me.name'   => 'Name' ],
                [ 'me.tier'   => 'Tier' ],
                [ 'me.rarity' => 'Rarity' ],
                [ 'vendor_items.id' => 'Vendor Sold' ],
                [ 'item_component_medical.base_toxicity'  => 'Toxicity' ],
                [ 'item_component_medical.strength_boost' => 'Str' ],
                [ 'item_component_medical.agility_boost'  => 'Agi' ],
                [ 'item_component_medical.stamina_boost'  => 'Sta' ],
            ],
        },
        weapon => {
            join => 'item_component_weapon',
            columns => [
                [ 'me.name'   => 'Name' ],
                [ 'me.tier'   => 'Tier' ],
                [ 'me.rarity' => 'Rarity' ],
                [ 'vendor_items.id' => 'Vendor Sold' ],
                [ 'item_component_weapon.is_long_range'   => 'Long Range' ],
                [ 'item_component_weapon.weapon_type'     => 'Type' ],
                [ 'item_component_weapon.energy_damage'   => 'Energy' ],
                [ 'item_component_weapon.impact_damage'   => 'Impact' ],
                [ 'item_component_weapon.piercing_damage' => 'Piercing' ],
                [ 'total_armor' => 'Total Damage', \'(item_component_weapon.energy_damage + item_component_weapon.impact_damage + item_component_weapon.piercing_damage) AS total_armor' ],
                [ 'item_component_weapon.accuracy'        => 'Accuracy' ],
            ],
        },
    );

    my @join_columns = qw( vendor_items );
    my @use_columns;
    if ( $item_type && exists $item_type_search{ $item_type->slug } ) {
        my $spec = $item_type_search{ $item_type->slug };
        push @join_columns, $spec->{join};
        @use_columns = @{ $spec->{columns} };
    }
    else {
        @use_columns = @$default_columns;
    }

    if ( $c->request->accepts('application/json') ) {
        $self->_output_json( $c, $item_type, \@use_columns, \@join_columns );
    }
    else {
        $self->_output_html( $c, $item_type, \@use_columns );
    }

    return;
}

sub _output_html {
    my ( $self, $c, $item_type, $use_columns ) = @_;

    if ( $item_type  ) {
        $c->stash->{item_type} = $item_type;

        if ( 'weapon' eq $item_type->slug ) {
            $c->stash->{weapon_types} = $c->model('DB')->resultset('ItemComponentWeapon')->search(
                    undef,
                    {
                        select   => ['weapon_type'],
                        as       => ['weapon_type'],
                        distinct => 1,
                        order_by => ['weapon_type'],
                    }
                )->get_column('weapon_type');
        }
    }

    my @known_params = qw(
        stale
        item_type
    );
    $c->stash->{known_params} = \@known_params;

    if ( $item_type ) {
        $c->stash->{legend} = $item_type->name;
    }

    $c->stash->{column_labels} = [
        ( map { $_->[1] } @$use_columns ),
        'In-game Link',
    ];

    my $max_tier_rs = $c->model('DB')->resultset('Item');
    if ( $item_type ) {
        $max_tier_rs = $max_tier_rs->search({ item_type_slug => $item_type->slug });
    }
    $c->stash->{max_tier} = $max_tier_rs->get_column('tier')->max;

    my $rarity_rs = $c->model('DB')->resultset('Item')->search(
        undef,
        {
            select   => ['rarity'],
            as       => ['rarity'],
            distinct => 1,
            order_by => ['rarity'],
        }
    );
    if ( $item_type ) {
        $rarity_rs = $rarity_rs->search({ item_type_slug => $item_type->slug });
    }
    $c->stash->{rarities} = $rarity_rs->get_column('rarity');

    return;
}

sub _output_json {
    my ( $self, $c, $item_type, $use_columns, $join_columns ) = @_;

    my $form = $c->stash->{form};

    my %search_cond = ();

    if ( $item_type && 'weapon' eq $item_type->slug ) {
        my $long_range = $form->param_value('sSearch_4');
        if ( $long_range ) {
            $search_cond{'item_component_weapon.is_long_range'} = $long_range;
        }

        my $search_weapon = $form->param_value('sSearch_5');
        if ( $search_weapon ) {
            $search_cond{'item_component_weapon.weapon_type'} = $search_weapon;
        }
    }

    my @use_as = map { my $x = $_->[0]; $x =~ s/\./_/g; $x } @$use_columns;

    my %search_attrs = (
        '+select' => [ map { exists $_->[2] ? $_->[2] : $_->[0] } @$use_columns ],
        '+as'     => \@use_as,
    );

    my $tier = $form->param_value('sSearch_1');
    if ( $tier ) {
        $search_cond{'me.tier'} = $tier;
    }

    my $rarity = $form->param_value('sSearch_2');
    if ( $rarity ) {
        $search_cond{'me.rarity'} = $rarity;
    }

    my $vendor_sold = $form->param_value('sSearch_3');
    if ( $vendor_sold  && 'Yes' eq $vendor_sold ) {
        $search_cond{'vendor_items.id'} = [
            {
                '=' => $c->model('DB')->resultset('VendorItem')->search(
                    {
                        'item_slug' => { -ident => 'me.slug' },
                    },
                    {
                        alias    => 'vi',
                        group_by => ['vi.id'],
                        rows     => 1,
                    },
                )->get_column('id')->as_query,
            }
        ];
    }
    elsif ( $vendor_sold  && 'No' eq $vendor_sold ) {
        $search_cond{'vendor_items.id'} = undef;
    }
    else {
        $search_cond{'vendor_items.id'} = [
            '-or' => {
                '=' => $c->model('DB')->resultset('VendorItem')->search(
                    {
                        'item_slug' => { -ident => 'me.slug' },
                    },
                    {
                        alias    => 'vi',
                        group_by => ['vi.id'],
                        rows     => 1,
                    },
                )->get_column('id')->as_query,
            }, {
                '=' => undef,
            }
        ];
    }

    if ( $c->request->param('stale') ) {
        $search_cond{description} = '';
    }

    if ( $item_type ) {
        $search_cond{item_type_slug} = $item_type->slug;
    }
    elsif ( $form->param_value('item_type') ) {
        # item_type was passed, but it didn't match anything in the db.
        # Still add the condition, to ensure we match no rows
        $search_cond{item_type_slug} = $form->param_value('item_type');
    }

    if ( @$join_columns ) {
        $search_attrs{join} = $join_columns;
    }

    my %dataTablesParams = $self->process_data_tables(
        $c,
        {
            colNames   => [ map { $_->[0] } @$use_columns ],
            sSortDir_0 => 'asc',
        },
    );

    %search_attrs = (
        %search_attrs,
        %{ $dataTablesParams{attrs} },
    );

    my $rs = $c->model('DB')->resultset('Item')->search(
        \%search_cond,
        \%search_attrs,
    );
    my @rows;

    while ( my $item = $rs->next ) {
        my @cols;
        for my $column (@use_as) {
            if ( 'me_name' eq $column ) {
                # column 1 - name / link
                push @cols, sprintf q{<a href="%s" class="list-title">%s</a>},
                    $c->uri_for( '/item', $item->slug )->as_string,
                    $item->name;
            }
            elsif ( 'vendor_items_id' eq $column ) {
                push @cols, ( $item->get_column('vendor_items_id') ? 'Yes' : 'No' );
            }
            else {
                push @cols, $item->get_column($column);
            }
        }

        # last column - in-game link
        push @cols, sprintf '<a href="%s" target="_blank">%s %s</a>',
            $item->in_game_link( $c ),
            'View in-game',
            '<span class="oi oi-external-link" title="External Link"></span>';

        push @rows, \@cols;
    }

    $c->stash->{rest} = $self->data_tables_response(
        $c,
        \%dataTablesParams,
        $rs,
        \@rows,
    );

    return;
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
