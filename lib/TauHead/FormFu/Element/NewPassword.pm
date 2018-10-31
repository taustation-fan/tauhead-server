package TauHead::FormFu::Element::NewPassword;
use Moose;

extends 'HTML::FormFu::Element::Password';

after BUILD => sub {
    my $self = shift;

    $self->name('password');

    $self->label('Password');

    $self->required('required');

    $self->constraints( [
        { type => 'Required' },
        { type => 'MinLength',
          min  => 8,
        },
        { type => '+TauHead::FormFu::Constraint::ContainsMultipleCharacterTypes' },
        { type    => 'Regex',
          regex   => '^\s',
          not     => 1,
          message => 'Can not start with whitespace.',
        },
        { type    => 'Regex',
          regex   => '\s$',
          not     => 1,
          message => 'Can not end with whitespace.',
        },
    ] );

    return;
};

__PACKAGE__->meta->make_immutable;

1;
