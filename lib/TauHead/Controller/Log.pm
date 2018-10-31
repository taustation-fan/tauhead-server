package TauHead::Controller::Log;
use Moose;
use DateTime;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);

    $c->assert_user_roles('admin');
}

sub log : Chained('/') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    my $log = $c->model('DB')->resultset('Log')->find( { id => $id } )
        or return $self->not_found($c);

    $c->stash->{log} = $log;
}

sub view : PathPart('') : Chained('log') : Args(0) {
}

sub end : ActionClass('RenderView') { }

__PACKAGE__->meta->make_immutable;

1;
