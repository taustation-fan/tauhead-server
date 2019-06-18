package TauHead::Controller::Scheduler::Wrecks_Looking_For_Trouble;
use Moose;
use Cpanel::JSON::XS;
use HTML::FormFu;
use Scalar::Util qw( reftype );
use Try::Tiny;
use utf8;
use namespace::autoclean;

BEGIN { extends 'TauHead::Controller::Scheduler' }

sub index : Private {
    my ( $self, $c ) = @_;

    $self->_wrecks_looking_for_trouble_search($c);
    $self->_wrecks_looking_for_trouble_loot($c);
}

sub _wrecks_looking_for_trouble_search {
    my ( $self, $c ) = @_;

    my $new_rs = $c->model('DB')->resultset('DataGatherer')->search(
        {
            action   => "wrecks_looking_for_trouble_search",
            claimed  => 0,
            held     => 0,
            complete => 0,
        },
        {
            order_by => { -asc => 'datetime_created' },
        }
    );

    my $form = $self->form;
    $form->load_config_filestem(
        $c->path_to( "root/forms/scheduler/wrecks_looking_for_trouble_search")
    );

    while ( my $result = $new_rs->next ) {
        $result->update({
            claimed          => 1,
            datetime_updated => \"NOW()",
        });

        $self->_validate_result_json( $result, $form )
            or next;

        my $params = $form->params;

        my $action_rs = $params->{current_station}->find_or_new_related(
            'action_counts',
            {
                action       => 'wrecks_looking_for_trouble_search',
                player_level => $params->{player_level},
            },
        );

        if ( $action_rs->in_storage ) {
            $action_rs->update({
                count => \'count+1',
            });
        }
        else {
            $action_rs->count(1);
            $action_rs->insert;
        }

        if ( ! $params->{campaign_level} ) {
            $result->update({
                complete         => 1,
                datetime_updated => \"NOW()",
            });
            next;
        }

        my $campaign_rs = $params->{current_station}->find_or_new_related(
            'l4t_campaigns',
            {
                campaign_level      => $params->{campaign_level},
                campaign_difficulty => $params->{campaign_difficulty},
                player_level        => $params->{player_level},
            });

        if ( $campaign_rs->in_storage ) {
            $campaign_rs->update({
                count => \'count+1',
            });
        }
        else {
            $campaign_rs->count(1);
            $campaign_rs->insert;
        }

        $result->update({
            complete         => 1,
            datetime_updated => \"NOW()",
        });
    }

    return;
}

sub _wrecks_looking_for_trouble_loot {
    my ( $self, $c ) = @_;

    my $item_rs = $c->model('DB')->resultset('Item');

    my $new_rs = $c->model('DB')->resultset('DataGatherer')->search(
        {
            action   => "wrecks_looking_for_trouble_loot",
            claimed  => 0,
            held     => 0,
            complete => 0,
        },
        {
            order_by => { -asc => 'datetime_created' },
        }
    );

    my $form = $self->form;
    $form->load_config_filestem(
        $c->path_to( "root/forms/scheduler/wrecks_looking_for_trouble_loot")
    );

    while ( my $result = $new_rs->next ) {
        $result->update({
            claimed          => 1,
            datetime_updated => \"NOW()",
        });

        $self->_validate_result_json( $result, $form )
            or next;

        my $params = $form->params;
        my $item = $item_rs->find({ name => $params->{campaign_loot} });
        if ( ! $item ) {
            $result->update({
                held             => 1,
                datetime_updated => \"NOW()",
                message          => "item not found",
            });
            next;
        };

        my $action_rs = $params->{current_station}->find_or_new_related(
            'action_counts',
            {
                action       => 'wrecks_looking_for_trouble_loot',
                player_level => $params->{player_level},
            },
        );

        if ( $action_rs->in_storage ) {
            $action_rs->update({
                count => \'count+1',
            });
        }
        else {
            $action_rs->count(1);
            $action_rs->insert;
        }

        my $loot_rs = $params->{current_station}->find_or_new_related(
            'loot_counts',
            {
                action       => 'wrecks_looking_for_trouble_loot',
                item_slug    => $item->slug,
                player_level => $params->{player_level},
            });

        if ( $loot_rs->in_storage ) {
            $loot_rs->update({
                count => \'count+1',
            });
        }
        else {
            $loot_rs->count(1);
            $loot_rs->insert;
        }

        $result->update({
            complete         => 1,
            datetime_updated => \"NOW()",
        });
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;
