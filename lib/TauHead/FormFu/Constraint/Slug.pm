package TauHead::FormFu::Constraint::Slug;
use Moose;

extends 'HTML::FormFu::Constraint::Regex';

after BUILD => sub {
    my $self = shift;

    $self->regex('^[^\s:/?#[\]@!$&\'()*+,;=]*\z');

    return;
};

1;
