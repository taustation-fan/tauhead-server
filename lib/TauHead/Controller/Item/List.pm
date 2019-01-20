package TauHead::Controller::Item::List;
use Moose;
use Try::Tiny;
use namespace::autoclean;

use TauHead::Util qw( html2text );

BEGIN { extends 'TauHead::BaseController' }

sub list : Path('') : Args(0) : FormConfig {
    my ( $self, $c ) = @_;

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
                [ 'item_component_weapon.accuracy'        => 'Accuracy' ],
            ],
        },
    );

    my %search_cond = ();

    my $item_type = scalar $c->request->param('item_type');
    if ( defined( $item_type ) && $item_type =~ /^[a-z-]+\z/ ) {
        $c->stash->{item_type} = $item_type;

        if ( 'weapon' eq $item_type ) {
            $c->stash->{weapon_types} = $c->model('DB')->resultset('ItemComponentWeapon')->search(
                    undef,
                    {
                        select   => ['weapon_type'],
                        as       => ['weapon_type'],
                        distinct => 1,
                        order_by => ['weapon_type'],
                    }
                )->get_column('weapon_type');

                my $long_range = scalar $c->request->param('sSearch_4');
                if ( defined( $long_range ) && $long_range =~ /^[01]\z/ ) {
                    $search_cond{'item_component_weapon.is_long_range'} = $long_range;
                }

                my $search_weapon = scalar $c->request->param('sSearch_5');
                if ( defined( $search_weapon ) && $search_weapon =~ /^[\w\s]+\z/ ) {
                    $search_cond{'item_component_weapon.weapon_type'} = $search_weapon;
                }
        }

        $item_type = $c->model('DB')->resultset('ItemType')->find({ slug => $item_type });
    }

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

    my @use_as = map { my $x = $_->[0]; $x =~ s/\./_/g; $x } @use_columns;

    my @known_params = qw(
        stale
        item_type
    );
    $c->stash->{known_params} = \@known_params;

    my %search_attrs = (
        '+select' => [ map { $_->[0] } @use_columns ],
        '+as'     => \@use_as,
    );

    my $tier = scalar $c->request->param('sSearch_1');
    if ( defined( $tier )  && $tier =~ /^[0-9]+\z/ ) {
        $search_cond{'me.tier'} = $tier;
    }

    my $rarity = scalar $c->request->param('sSearch_2');
    if ( defined( $rarity )  && $rarity =~ /^[\w]+\z/ ) {
        $search_cond{'me.rarity'} = $rarity;
    }

    my $vendor_sold = scalar $c->request->param('sSearch_3');
    if ( defined( $vendor_sold )  && 'Yes' eq $vendor_sold ) {
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
    elsif ( defined( $vendor_sold )  && 'No' eq $vendor_sold ) {
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
        $c->stash->{legend} = $item_type->name;
    }

    if ( @join_columns ) {
        $search_attrs{join} = \@join_columns;
    }

    $c->stash->{column_labels} = [
        ( map { $_->[1] } @use_columns ),
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

    return unless $c->request->accepts('application/json');

    my %dataTablesParams = $self->process_data_tables(
        $c,
        {
            colNames   => [ map { $_->[0] } @use_columns ],
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
