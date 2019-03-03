package TauHead::Controller::API::Add_Area_NPCs;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);

    $c->check_any_user_role(qw( api_update_area_npcs api admin ));
}

sub index : Path('/api/add_area_npcs') : Args(0) : FormConfig {}

sub index_FORM_NOT_VALID {
    my ( $self, $c ) = @_;

    $c->stash->{rest}
        = { errors => $c->stash->{form}->jquery_validation_errors_join('<br/>')};
}

sub index_FORM_VALID {
    my ( $self, $c ) = @_;

    my $form   = $c->stash->{form};
    my $params = $form->params;
    my $schema = $c->model('DB');

    # find system
    my $system_name = $form->param_value('system');
    my $system = $schema->resultset('System')->find( { name => $system_name } )
        or return $self->invalidate_form( $c, 'system', 'System not found' );

    # find station
    my $station_name = $form->param_value('station');
    my $station = $schema->resultset('Station')->find({
        system_slug => $system->slug,
        name        => $station_name,
     }) or return $self->invalidate_form( $c, 'station', 'Station not found' );

    # find area
    my $area_slug = $form->param_value('area_slug');
    my $area = $schema->resultset('Area')->find({
        station_slug => $station->slug,
        slug         => $area_slug,
    }) or return $self->invalidate_form( $c, 'area_slug', 'Area not found' );

    # NPCs
    my $npc_count = $form->param_value('npc_counter');
    if ( !$npc_count ) {
        return $self->invalidate_form( $c, 'npc_1.name', 'No NPCs found in Area' );
    }

    my $rep_blocks = $form->get_element({ type => 'Repeatable' })->get_elements;
    my $npc_rs     = $schema->resultset('NPC');
    my $item_rs    = $schema->resultset('Item');

    my $update = $form->valid('submit');
    my @missing_items;
    my $changed;

    for my $i ( 1 .. $npc_count ) {
        my $block        = $rep_blocks->[$i-1];
        my $block_params = $params->{"npc_$i"};
        my $slug         = $block_params->{slug};

        my $npc = $npc_rs->find_or_new({ slug => $slug });
        my $rel = $npc->find_or_new_related( 'area_npcs', { area_id => $area->id });

        $npc->name( $block_params->{name} );

        # check if weapon/armor already exists
        for my $type (qw( primary_weapon armor )) {
            my $type_slug = $type . "_slug";
            my $value = $block_params->{$type_slug};
            if ( defined $value
                && length $value )
            {
                my $item = $item_rs->find_or_new({ slug => $value });
                if ( !$item->in_storage ) {
                    push @missing_items, [
                        "npc_$i.$type_slug",
                        sprintf( "Unknown item - add it first: %s", $item->in_game_link($c) ),
                    ];
                    undef $update;
                }
                $npc->$type_slug( $value );
            }
            else {
                $npc->$type_slug( undef );
            }
        }

        my @changed_cols = $npc->is_changed;

        if ( $npc->in_storage ) {
            if ( @changed_cols ) {
                if ($update) {
                    $changed = 1;
                    $npc->update;
                    $rel->insert if !$rel->in_storage;
                }
                else {
                    $block->add_attrs({ class => 'border-danger' });
                    $block->element({
                        type    => 'Block',
                        content => 'NPC changed - will update',
                        attrs => {
                            class => 'alert alert-danger',
                        },
                    });
                }

                for my $key ( @changed_cols ) {
                    if ( ! $update ) {
                        $npc->discard_changes;
                        $block->get_field({ nested_name => "npc_$i.$key" })
                            ->add_attrs({ class => 'alert-danger' })
                            ->comment( sprintf "Changed: was '%s'", $npc->$key );
                    }
                }
            }
            else {
                if ( $rel->in_storage ) {
                    $block->add_attrs({ class => 'border-success' });
                    $block->element({
                        type    => 'Block',
                        content => 'No change required',
                        attrs => {
                            class => 'alert alert-success',
                        },
                    });
                }
                else {
                    if ( $update ) {
                        $rel->insert;
                    }
                    else {
                        $block->add_attrs({ class => 'border-warning' });
                        $block->element({
                            type    => 'Block',
                            content => 'NPC exists but is not linked to this Area - will add link',
                            attrs => {
                                class => 'alert alert-warning',
                            },
                        });
                    }
                }
            }
        }
        else { # new NPC
            if ($update) {
                $changed = 1;
                $npc->insert;
                $rel->insert;
            }
            else {
                $block->add_attrs({ class => 'border-warning' });
                $block->element({
                    type    => 'Block',
                    content => 'NPC is new - will be added',
                    attrs => {
                        class => 'alert alert-warning',
                    },
                });
            }
        }
    }

    if ( @missing_items ) {
        return $self->invalidate_form( $c, \@missing_items );
    }

     if ( $update ) {
         my $msg = $changed ? "NPC updated" : "No change required";

         my $redirect = $c->uri_for( "/system", $system->slug, "station", $station->slug, "area", $area->slug, { mid => $c->set_status_msg($msg) } );

         $c->stash->{rest} = {
             ok       => 1,
             redirect => $redirect->as_string,
         };

         $self->add_log( $c, 'api/add_area_npcs',
             {
                 description => "API Added Area NPCs",
                 area_id     => $area->id,
             },
         );

         $c->detach;
     }
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
