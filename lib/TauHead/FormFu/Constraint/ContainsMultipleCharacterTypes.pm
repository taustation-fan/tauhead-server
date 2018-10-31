package TauHead::FormFu::Constraint::ContainsMultipleCharacterTypes;
use Moose;

extends 'HTML::FormFu::Constraint';

after BUILD => sub {
    my $self = shift;

    $self->message(<<MSG);
Must contain at least 3 types of either lowercase, uppercase, numeric, or special character.
MSG

    return;
};

sub constrain_value {
    my ( $self, $value ) = @_;

    my $lower = $value;
    $lower =~ s/[^a-z]//g;

    my $upper = $value;
    $upper =~ s/[^A-Z]//g;

    my $digit = $value;
    $digit =~ s/[^0-9]//g;

    my $other = length $value;
    $other -= length $lower;
    $other -= length $upper;
    $other -= length $digit;

    my $types = 0;
    $types++ if length $lower;
    $types++ if length $upper;
    $types++ if length $digit;
    $types++ if $other;

    return $types >= 3;
}

1;
