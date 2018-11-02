package TauHead::Controller::API::Update_Items;
use Moose;
use Cpanel::JSON::XS ();
use List::Util qw( all );
use Scalar::Util qw( reftype );
use TauHead::Util qw( camel2words );
use Try::Tiny;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

# following arrays should be kept in sync with vars
# in firefox addon `source.js`
my @item_type_fields = (
    'name',
    'slug',
);

my @item_fields = (
    'name',
    'slug',
    'image',
    'tier',
    'stack_size',
    'bonds',
    'mass',
    'rarity',
);

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);

    $c->check_any_user_role(qw( api_update_items api admin ));
}

sub index : Path('/api/update_items') : Args(0) : FormConfig { }

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
    my $update = $form->valid('submit');

    my $changed;
    my ( $item_types_rep, $items_rep )
        = @{ $form->get_elements({ type => 'Repeatable' }) };

    my ( %seen_item_type, %seen_item );

    # Item Types
    {
        my $item_type_count = $form->param_value('item_type_counter');
        if ( !$item_type_count ) {
            return $self->invalidate_form( $c, 'item_type_1.id', 'No Item Types found in Itinerary' );
        }

        my $rep_blocks    = $item_types_rep->get_elements;
        my $item_types_rs = $schema->resultset('ItemType');

        for my $i ( 1 .. $item_type_count ) {
            my $block        = $rep_blocks->[$i-1];
            my $block_params = $params->{"item_type_$i"};
            my $slug         = $block_params->{slug};

            my $item_type = $item_types_rs->find_or_new({ slug => $slug });

            for my $key ( @item_type_fields ) {
                $item_type->$key( $block_params->{$key} );
            }

            my @changed_cols = $item_type->is_changed;

            if ( $item_type->in_storage ) {
                if ( @changed_cols ) {
                    if ($update) {
                        $changed = 1;
                        $item_type->update;
                    }
                    else {
                        $block->add_attrs({ class => 'border-danger' });
                        $block->element({
                            type    => 'Block',
                            content => 'Item Type changed - will update',
                            attrs => {
                                class => 'alert alert-api alert-danger',
                            },
                        });
                    }

                    for my $key ( @changed_cols ) {
                        if ( ! $update ) {
                            $block->get_field({ nested_name => "item_type_$i.$key" })
                                ->add_attrs({ class => 'alert-danger' })
                                ->comment("$key changed");
                        }
                    }
                }
                else {
                    $block->add_attrs({ class => 'border-success' });
                    $block->element({
                        type    => 'Block',
                        content => 'No change required',
                        attrs => {
                            class => 'alert alert-api alert-success',
                        },
                    });
                }
            }
            else { # new item-type
                if ($update) {
                    $changed = 1;
                    $item_type->insert;
                }
                else {
                    $block->add_attrs({ class => 'border-warning' });
                    $block->element({
                        type    => 'Block',
                        content => 'Item Type is new - will be added',
                        attrs => {
                            class => 'alert alert-api alert-warning',
                        },
                    });
                }
            }
            $seen_item_type{$slug} = $item_type;
        }
    };

    # Items
    {
        my $item_count = $form->param_value('item_counter');
        if ( !$item_count ) {
            return $self->invalidate_form( $c, 'item_1.slug', 'No Items found in Itinerary' );
        }

        my $rep_blocks = $items_rep->get_elements;
        my $items_rs   = $schema->resultset('Item');
        my %comp_columns_info;

        for my $i ( 1 .. $item_count ) {
            my $block          = $rep_blocks->[$i-1];
            my $block_params   = $params->{"item_$i"};
            my $slug           = $block_params->{slug};
            my $item_type_slug = $block_params->{item_type_slug};

            my $item = $items_rs->find_or_new({
                slug           => $slug,
                item_type_slug => $item_type_slug,
            });

            for my $key ( @item_fields ) {
                $item->$key( $block_params->{$key} );
            }

            if ( ! $seen_item_type{ $item->item_type_slug } ) {
                die "Should never get an item without a matching item-type";
            }

            my @changed_cols = $item->is_changed;

            if ( $item->in_storage ) {
                if ( @changed_cols ) {
                    if ($update) {
                        $changed = 1;
                        $item->update;
                    }
                    else {
                        $block->add_attrs({ class => 'border-danger' });
                        $block->element({
                            type    => 'Block',
                            content => 'Item changed - will update',
                            attrs => {
                                class => 'alert alert-api alert-danger',
                            },
                        });
                    }

                    for my $key ( @changed_cols ) {
                        if ( ! $update ) {
                            $block->get_field({ nested_name => "item_$i.$key" })
                                ->add_attrs({ class => 'alert-danger' })
                                ->comment("$key changed");
                        }
                    }
                }
                else {
                    $block->add_attrs({ class => 'border-success' });
                    $block->element({
                        type    => 'Block',
                        content => 'No change required',
                        attrs => {
                            class => 'alert alert-api alert-success',
                        },
                    });
                }
            }
            else { # new item
                if ($update) {
                    $changed = 1;
                    $item->insert;
                }
                else {
                    $block->add_attrs({ class => 'border-warning' });
                    $block->element({
                        type    => 'Block',
                        content => 'Item is new - will be added',
                        attrs => {
                            class => 'alert alert-api alert-warning',
                        },
                    });
                }
            }

            # Item components
            for my $comp_type ( map {"item_component_$_"} qw(armor medical mod weapon) ) {
                $seen_item{$slug} = $item;
                my $comp        = $item->find_or_new_related($comp_type, {});
                my $comp_block  = $block->get_element({ nested_name => $comp_type, type => 'Fieldset' });
                my $comp_params = $block_params->{$comp_type};
                my $has_params  = scalar grep {length $_} values %$comp_params;

                if ( !$comp->in_storage && !$has_params ) {
                    # hide Fieldset
                    $comp_block->attributes({
                        style => 'visibility: hidden; position: absolute',
                    });
                    next;
                }

                $comp_columns_info{$comp_type} ||= $comp->columns_info;

                # don't update if not in storage, and all values are undef / zero / empty
                if ( !$comp->in_storage ) {
                    my @values = map { $comp_params->{$_} }
                        @{ $comp->api_update_columns };
                    if ( all { ( !defined $_ ) || ( 0 == $_ ) || ( '' eq $_ ) } @values ) {
                        # hide Fieldset
                        $comp_block->attributes({
                            style => 'visibility: hidden; position: absolute',
                        });
                        next;
                    }
                }

                for my $col ( @{ $comp->api_update_columns } ) {
                    # don't update nullable columns with submitted empty string
                    if (
                        !defined ( $comp->$col )
                        && $comp_columns_info{$comp_type}{$col}{is_nullable}
                        && "" eq $comp_params->{$col}
                    ) {
                        next;
                    }

                    $comp->$col( $comp_params->{$col} );
                }

                my @changed_cols = $comp->is_changed;

                if ( $comp->in_storage ) {
                    if ( @changed_cols ) {
                        if ($update) {
                            if ($has_params) {
                                $comp->update;
                            }
                            else {
                                $comp->delete;
                            }
                            $changed = 1;
                        }
                        else {
                            my $msg = $has_params
                                ? sprintf( '%s changed - will update', camel2words($comp_type) )
                                : sprintf( '%s will be deleted', camel2words($comp_type) );

                            $comp_block->add_attrs({ class => 'border-danger' });
                            $comp_block->element({
                                type    => 'Block',
                                content => $msg,
                                attrs => {
                                    class => 'alert alert-api alert-danger',
                                },
                            });

                            if ($has_params) {
                                for my $key ( @changed_cols ) {
                                    if ( ! $update ) {
                                        $comp_block->get_field({ nested_name => "item_$i.$comp_type.$key" })
                                            ->add_attrs({ class => 'alert-danger' })
                                            ->comment(sprintf("%s changed", camel2words($key)));
                                    }
                                }
                            }
                        }
                    }
                }
                elsif ($has_params) { # not in storage - new component
                    if ($update) {
                        $changed = 1;
                        $comp->insert;
                    }
                    else {
                        $comp_block->add_attrs({ class => 'border-warning' });
                        $comp_block->element({
                            type    => 'Block',
                            content => sprintf( '%s is new - will be added', camel2words($comp_type) ),
                            attrs => {
                                class => 'alert alert-api alert-warning',
                            },
                        });
                    }
                }
            }
        }

    };

    if ( $update ) {
        my $msg = $changed ? "Items updated" : "No change required";

        # redirect to Item List
        my $redirect = $c->uri_for( "/item/list", { mid => $c->set_status_msg($msg) } );

        $c->stash->{rest} = {
            ok       => 1,
            redirect => $redirect->as_string,
        };

        $self->add_log( $c, 'api/update_items',
            {
                description => "API Updated Items",
            },
        );

        $c->detach;
    }
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
