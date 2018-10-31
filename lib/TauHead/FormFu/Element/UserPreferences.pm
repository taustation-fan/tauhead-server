package TauHead::FormFu::Element::UserPreferences;

use Moose;
extends 'HTML::FormFu::Element::Block';

use Carp qw( croak );

after pre_process => sub {
    my $self = shift;

    my $user = $self->form->stash->{context}->user->obj;

    my $prefs = $user->search_related(
        'user_preferences',
        undef,
        {
            order_by => ['preference_id'],
        },
    );

    while ( my $user_pref = $prefs->next ) {
        my $pref = $user_pref->preference;
        my $field;

        if ( 'BOOL' eq $pref->data_type ) {
            $field = $self->element( {
                type    => 'Radiogroup',
                name    => $user_pref->preference_id,
                container_attributes => {
                    class => 'form-group'
                },
                options => [
                    {
                        value => 0,
                        label => 'No',
                        container_attributes => {
                            class => 'form-check'
                        },
                        attributes => {
                            class => 'form-check-input'
                        },
                        label_attributes => {
                            class => 'form-check-label',
                        }
                    },
                    {
                        value => 1,
                        label => 'Yes',
                        container_attributes => {
                            class => 'form-check'
                        },
                        attributes => {
                            class => 'form-check-input'
                        },
                        label_attributes => {
                            class => 'form-check-label',
                        }
                    }
                ],
                label_tag => 'label',
                auto_id   => '%f_%n_%c',
            } );

            $field->constraints( [
              { type => 'Required' },
              { type => 'Set',
                set  => [ 0, 1 ],
              },
            ] );
        }
        else {
            croak "other preference types are not implemented";
        }

        $field->label(   $pref->display_label );
        $field->comment( $pref->description );
        $field->default( $user_pref->value );
    }

    return;
};

__PACKAGE__->meta->make_immutable;

1;
