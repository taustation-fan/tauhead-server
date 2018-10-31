package TauHead::FormFu::Element::MessageContainer;

use Moose;
extends 'HTML::FormFu::Element::Block';

after BUILD => sub {
    my $self = shift;

    $self->add_attrs(
        {   style => 'display: none',
            class => 'formfu-message-container alert',
        } );

    $self->element(
        {   type      => 'Block',
            tag       => 'span',
            content   => '',
            add_attrs => {
                style => 'font-weight: bold',
                class => 'message',
            },
        } );

    return;
};

__PACKAGE__->meta->make_immutable;

1;
