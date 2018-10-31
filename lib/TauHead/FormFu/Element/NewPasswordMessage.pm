package TauHead::FormFu::Element::NewPasswordMessage;
use Moose;

extends 'HTML::FormFu::Element::Block';

after BUILD => sub {
    my $self = shift;

    $self->attrs({
        class => 'alert alert-info',
        role  => 'alert',
    });

    $self->content_xml(<<XML);
Your password must be at least 8 characters long. <br />
It cannot start or end in whitespace. <br />
It must have at least 3 types of either uppercase, lowercase, numeric or special characters.
XML

    return;
};

__PACKAGE__->meta->make_immutable;

1;
