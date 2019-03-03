package TauHead::FormFu::Constraint::ExactValueCount;
use Moose;
use MooseX::Attribute::Chained;

extends 'HTML::FormFu::Constraint';

use Carp qw( croak );

has count => ( is => 'rw', traits => ['Chained'] );

sub constrain_value {
    my ( $self, $value ) = @_;

    croak "constraint 'count' is not set"
        if !defined $self->count;

    return if $self->count == 1;

    croak;
}

sub constrain_values {
    my ( $self, $values ) = @_;

    croak "constraint 'count' is not set"
        if !defined $self->count;

    return if $self->count == scalar @$values;

    croak;
}

__PACKAGE__->meta->make_immutable;

1;
