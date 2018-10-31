package TauHead::FormFu::Element::ErrorContainer;

use Moose;
extends 'HTML::FormFu::Element::Block';

after BUILD => sub {
    my $self = shift;

    $self->add_attrs(
        {   style => 'display: none',
            class => 'formfu-error-container form-group has-error',
        } );

    $self->element(
        {   type      => 'Block',
            tag       => 'span',
            content   => '',
            add_attrs => {
                style => 'font-weight: bold',
                class => 'control-label',
            },
        } );

    return;
};

__PACKAGE__->meta->make_immutable;

1;
