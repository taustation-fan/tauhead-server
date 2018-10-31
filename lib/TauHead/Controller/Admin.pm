package TauHead::Controller::Admin;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);

    $c->assert_user_roles('admin');
}

sub admin : Chained('/') : CaptureArgs(0) {
}

__PACKAGE__->meta->make_immutable;

1;
