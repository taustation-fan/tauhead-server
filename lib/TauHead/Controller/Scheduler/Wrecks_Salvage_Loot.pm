package TauHead::Controller::Scheduler::Wrecks_Salvage_Loot;
use Moose;
use Cpanel::JSON::XS;
use HTML::FormFu;
use Try::Tiny;
use utf8;
use namespace::autoclean;

BEGIN { extends 'TauHead::Controller::Scheduler' }

sub index : Private {
    my ( $self, $c ) = @_;

    my $item_rs = $c->model('DB')->resultset('Item');

    my $new_rs = $c->model('DB')->resultset('DataGatherer')->search(
        {
            action   => "wrecks_salvage_loot",
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
        $c->path_to( "root/forms/scheduler/wrecks_salvage_loot")
    );

    while ( my $result = $new_rs->next ) {
        $result->update({
            claimed          => 1,
            datetime_updated => \"NOW()",
        });

        $self->_validate_result_json( $result, $form )
            or next;

        my $params = $form->params;
        my $item;
        if ( $params->{salvage_success} ) {
            $item = $item_rs->find({ name => $params->{salvage_loot} });
            if ( ! $item ) {
                $result->update({
                    held             => 1,
                    datetime_updated => \"NOW()",
                    message          => "item not found",
                });
                next;
            };
        }

        my $action_rs = $form->params->{current_station}->find_or_new_related(
            'action_counts',
            {
                action       => 'wrecks_salvage_loot',
                player_level => $form->params->{player_level},
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

        if ( ! $form->params->{salvage_success} ) {
            $result->update({
                complete         => 1,
                datetime_updated => \"NOW()",
            });
            next;
        }

        my $loot_rs = $form->params->{current_station}->find_or_new_related(
            'loot_counts',
            {
                action       => 'wrecks_salvage_loot',
                item_slug    => $item->slug,
                player_level => $form->params->{player_level},
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
