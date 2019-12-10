package TauHead::Controller::API::Log_Auctions;
use Moose;
use Cpanel::JSON::XS ();
use DateTime::Format::TauStation;
use List::Util qw( uniq );
use Try::Tiny;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);

    $c->check_any_user_role(qw( api_log_auctions api admin ));
}

sub index : Path('/api/log_auctions') : Args(0) : FormConfig { }

sub index_FORM_NOT_VALID {
    my ( $self, $c ) = @_;

    $c->stash->{rest}
        = { errors => $c->stash->{form}->jquery_validation_errors_join('<br/>'),
        };
}

sub index_FORM_VALID {
    my ( $self, $c ) = @_;

    my $form   = $c->stash->{form};
    my $params = $form->params;
    my $schema = $c->model('DB');

    my $user_account_id      = $c->user->obj->id;
    my $gct          = $params->{gct};
    my $gct_datetime = DateTime::Format::TauStation->parse_datetime( $gct );
    my $added        = 0;
    my @missing_items;

    # Listings
    my $auction_count = $form->param_value('auction_counter');
    if ( !$auction_count ) {
        return $self->invalidate_form( $c, 'auction_1.slug', 'No auctions found in Itinerary' );
    }

    my $item_rs            = $schema->resultset('Item');
    my $auctions_rs        = $schema->resultset('AuctionListing');
    my $auctions_record_rs = $schema->resultset('AuctionListingRecord');

    for my $i ( 1 .. $auction_count ) {
        my $block_params = $params->{"auction_$i"};
        if ( ! $item_rs->find( $block_params->{item_slug} ) ) {
            push @missing_items, $block_params->{item_slug};
        }
    }

    if (@missing_items) {
        $c->stash->{missing_items} = [ uniq @missing_items ];
        $c->detach;
    }

    for my $i ( 1 .. $auction_count ) {
        my $block_params = $params->{"auction_$i"};

        my $auction = $auctions_rs->find_or_new({
            auction_id => $block_params->{auction_id},
        });

        $auction->last_seen_gct( $gct );
        $auction->last_seen_datetime( $gct_datetime );

        if ( $auction->in_storage ) {
            $auction->update;
        }
        else { # new Listing
            $auction->first_seen_gct( $gct );
            $auction->first_seen_datetime( $gct_datetime );
            $auction->item_slug(   $block_params->{item_slug} );
            $auction->quantity(    $block_params->{quantity} );
            $auction->price(       $block_params->{price} );
            $auction->seller_slug( $block_params->{seller_slug} );
            $auction->seller_name( $block_params->{seller_name} );

            $auction->insert;
        }

        try {
            $auction->create_related(
                'auction_listing_records',
                {
                    gct      => $gct,
                    datetime => $gct_datetime,
                    user_account_id  => $user_account_id,
                },
            );
            $added++;
        }
    }

    my $msg = "$added auctions successfully saved";

    $c->stash->{rest} = {
        ok      => 1,
        message => $msg,
    };

    $self->add_log( $c, 'api/log_auctions',
        {
            description => "API Logged Auctions",
        },
    );

    $c->detach;
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
