package TauHead::Controller::API::Update_Item;
use Moose;
use Cpanel::JSON::XS ();
use List::Util qw( all );
use Scalar::Util qw( reftype );
use TauHead::Util qw( camel2words );
use Try::Tiny;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

my @item_fields = (
    'name',
    'slug',
    'image',
    'item_type_slug',
    'tier',
    'mass',
    'rarity',
    'value',
    'description',
);

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);

    $c->check_any_user_role(qw( api_update_item api admin ));
}

sub index : Path('/api/update_item') : Args(0) : FormConfig { }

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
    my $changed;

    my $slug = $params->{slug};
    my $item = $schema->resultset('Item')->find_or_new({
        slug => $slug,
    });

    # Item-type
    my $item_type_slug  = $params->{item_type_slug};
    my $item_type_name  = $params->{item_type_name};
    my $item_type_field = $form->get_field('item_type_name');
    my $item_type = $schema->resultset('ItemType')->find_or_new({
        slug => $item_type_slug,
    });
    if ( $item_type->in_storage ) {
        # already exists - user needn't see anything
        $item_type_field->parent->remove_element( $item_type_field );

    }
    elsif ( defined($item_type_name) && length $item_type_name ) {
        $item_type->name( $item_type_name );
        $item_type->insert;
    }
    else {
        return $self->invalidate_form( $c, 'item_type_name', 'Required' );
    }

    # Item
    for my $key ( @item_fields ) {
        $item->$key( $params->{$key} );
    }

    my @changed_cols = $item->is_changed;

    if ( $item->in_storage ) {
        if ( @changed_cols ) {
            $changed = 1;
            $item->update;
        }
    }
    else { # new item
        $changed = 1;
        $item->insert;
    }

    # Item components
    for my $comp_type ( map {"item_component_$_"} qw(armor medical weapon) ) {
        # Don't handle 'mod' - currently not implemented in-game
        my $comp        = $item->find_or_new_related($comp_type, {});
        my $comp_block  = $form->get_element({ nested_name => $comp_type, type => 'Fieldset' });
        my $comp_params = $params->{$comp_type};
        my $has_params  = scalar grep {length $_} values %$comp_params;

        if ( !$has_params ) {
            next;
        }

        # don't update if not in storage, and all values are undef / zero / empty
        if ( !$comp->in_storage ) {
            my @values = map { $comp_params->{$_} }
                @{ $comp->api_update_columns };

            if ( all { ( !defined $_ ) || ( 0 == $_ ) || ( '' eq $_ ) } @values ) {
                next;
            }
        }

        for my $col ( @{ $comp->api_update_columns } ) {
            # don't update nullable columns with submitted empty string
            if (
                !defined ( $comp->$col )
                && $comp->columns_info->{$comp_type}{$col}{is_nullable}
                && "" eq $comp_params->{$col}
            ) {
                next;
            }

            $comp->$col( $comp_params->{$col} );
        }

        my @changed_cols = $comp->is_changed;

        if ( $comp->in_storage ) {
            if ( @changed_cols ) {
                if ($has_params) {
                    $comp->update;
                }
                else {
                    $comp->delete;
                }
                $changed = 1;
            }
        }
        elsif ($has_params) { # not in storage - new component
            $changed = 1;
            $comp->insert;
        }
    }

    $self->add_log( $c, 'api/update_item',
        {
            description => "API Updated Item",
        },
    );

    my $msg = $changed ? "Item updated" : "No change required";

    $c->stash->{rest} = {
        ok      => 1,
        message => $msg,
    };

    $c->detach;
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
