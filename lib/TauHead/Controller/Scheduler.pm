package TauHead::Controller::Scheduler;
use Moose;
use Cpanel::JSON::XS;
use HTML::FormFu;
use Scalar::Util qw( reftype );
use Try::Tiny;
use utf8;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub default : Path {
    my ( $self, $c ) = @_;

    $c->response->status(204);
    $c->response->content_length(0);
    $c->response->body("");
}

sub wrecks_salvage_loot : Private {
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

sub wrecks_looking_for_trouble : Private {
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

sub wrecks_sewers_loot : Private {
    my ( $self, $c ) = @_;

    my $item_rs = $c->model('DB')->resultset('Item');

    my $new_rs = $c->model('DB')->resultset('DataGatherer')->search(
        {
            action   => "wrecks_sewers_loot",
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
        $c->path_to( "root/forms/scheduler/wrecks_sewers_loot")
    );

    while ( my $result = $new_rs->next ) {
        $result->update({
            claimed          => 1,
            datetime_updated => \"NOW()",
        });

        $self->_validate_result_json( $result, $form )
            or next;

        my $params = $form->params;
        my @item;
        for my $item_name ( @{ $params->{campaign_loot} } ) {
            my $item = $item_rs->find({ name => $item_name })
                or next;

            push @item, $item;
        }

        if ( 2 != scalar @item ) {
            $result->update({
                held             => 1,
                datetime_updated => \"NOW()",
                message          => "item not found",
            });
            next;
        }

        my $action_rs = $form->params->{current_station}->find_or_new_related(
            'action_counts',
            {
                action       => 'wrecks_sewers_loot',
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

        for my $item (@item) {
            my $loot_rs = $form->params->{current_station}->find_or_new_related(
                'loot_counts',
                {
                    action       => 'wrecks_sewers_loot',
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
        }

        $result->update({
            complete         => 1,
            datetime_updated => \"NOW()",
        });
    }

    return;
}

sub _validate_result_json {
    my ( $self, $result, $form ) =  @_;

    my $json;
    my $ok;
    $ok = try {
        $json = Cpanel::JSON::XS->new->decode( $result->json );
        1;
    };
    if ( ! $ok ) {
        $result->update({
            held             => 1,
            datetime_updated => \"NOW()",
            message          => "json decode failed",
        });
        return;
    }

    $ok = try {
        $form->process($json);
        1;
    }
    catch {
        $result->update({
            held             => 1,
            datetime_updated => \"NOW()",
            message          => "form process failed",
        });
        return undef;
    };
    return unless $ok;

    if ( !$form->submitted_and_valid ) {
        $result->update({
            held             => 1,
            datetime_updated => \'NOW()',
            message          => "form not valid",
        });
        return;
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
