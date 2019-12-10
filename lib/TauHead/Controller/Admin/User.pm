package TauHead::Controller::Admin::User;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub user : Chained('../admin') : CaptureArgs(1) {
    my ( $self, $c, $user_account_id ) = @_;

    my $view_user = $c->model('DB')->resultset('UserAccount')->find( $user_account_id )
        or return $self->not_found($c);

    $c->stash->{view_user} = $view_user;
}

sub view : PathPart('') : Chained('user') : Args(0) {
    my ( $self, $c, $user_account_id ) = @_;

    my $view_user = $c->stash->{view_user};

    my $last_login = $view_user->last_login;
    if ( $last_login ) {
        $c->stash->{last_login} = $last_login->datetime->strftime('%F');
    }
    else {
        $c->stash->{last_login} = 'Never';
    }

    return;
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
