package TauHead::Controller::Account;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);
}

sub account : Path('/account') : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{user} = $c->user->obj;
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
