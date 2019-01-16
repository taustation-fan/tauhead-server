package TauHead::Controller::Item::List;
use Moose;
use Try::Tiny;
use namespace::autoclean;

use TauHead::Util qw( html2text );

BEGIN { extends 'TauHead::BaseController' }

sub list : Path('') : Args(0) : FormConfig {
    my ( $self, $c ) = @_;

    my $form = $c->stash->{form};
    my %dataTablesParams = $self->process_data_tables(
        $c,
        {
            colNames => [
                'me.name',
                'me.tier',
                'me.value',
                'me.mass',
                'vendor_items.price',
                'vendor_items.price_unit',
                # don't add column 6 - it's not a DBIx::Class field
            ],
            sSortDir_0 => 'asc',
        },
    );

    my %params = (
        stale => 1,
    #     ip_address  => sub { sprintf "IP Address: %s", html2text( $_[0] ) },
    #     user_id     => sub { sprintf "user #%d", html2text( $_[0] ) },
    #     guid        => sub { sprintf "GUID: %s", html2text( $_[0] ) },
    #     owner_id    => sub { sprintf "association with user #%d", html2text( $_[0] ) },
    );

    $c->stash->{known_params} = [ keys %params ];

    my %cond = (
        'vendor_items.id' => [
            '-or' => {
                '=' => $c->model('DB')->resultset('VendorItem')->search(
                    {
                        'item_slug' => { -ident => 'me.slug' },
                    },
                    {
                        alias    => 'vi',
                        group_by => ['vi.id'],
                        order_by => { -asc => 'vi.price' },
                        rows     => 1,
                    },
                )->get_column('id')->as_query,
            }, {
                '=' => undef,
            }
        ]
    );

    if ( $c->request->param('stale') ) {
        $cond{'description'} = '';
    }
    # for my $param ( keys %params ) {
    #     if ( my $query = scalar $c->request->param( $param ) ) {
    #         $cond{$param} = $query;
    #         try {
    #             $c->stash->{legend} = $params{$param}->( $query );
    #         };
    #         last;
    #     }
    # }

    return unless $c->request->accepts('application/json');

    my $rs = $c->model('DB')->resultset('Item')->search(
        \%cond,
        {
            join => [ 'item_type', 'vendor_items' ],
            '+select' => [ 'item_type.name', 'vendor_items.price', 'vendor_items.price_unit' ],
            '+as'     => [ 'item_type_name', 'vendor_item_price', 'vendor_item_price_unit' ],
            %{ $dataTablesParams{attrs} },
        },
    );
    my @rows;

    while ( my $item = $rs->next ) {
        my @cols;
        # column 1 - name / link
        push @cols, sprintf q{<a href="%s" class="list-title">%s</a>},
            $c->uri_for( '/item', $item->slug )->as_string,
            $item->name;

        # column 2 - tier
        push @cols, $item->tier;

        # column 3 - value
        push @cols, $item->value;

        # column 4 - mass
        push @cols, $item->mass;

        # column 5 - price
        push @cols, $item->get_column('vendor_item_price');

        # column 6 - price_unit
        push @cols, ucfirst $item->get_column('vendor_item_price_unit');

        # column 7 - in-game link
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
