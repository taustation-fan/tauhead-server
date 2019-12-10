package TauHead::Controller::Verify_Email;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub verify_email : Path('/verify-email') : Args(1) {
    my ( $self, $c, $guid ) = @_;

    if ( $c->user_exists ) {
        $self->redirect_with_msg( "Logged-in users cannot verify a new account." );
    }

    my $verify = $c->model('DB')->resultset('VerifyEmailRequest')->find($guid);
    if ( !$verify ) {
        $c->stash->{error} = 'Verification code no longer valid';
        $c->detach;
    }

    my $user = $verify->user_account;
    $user->update( { email_confirmed => 1, } );

    $c->model('DB')->resultset('VerifyEmailRequest')
        ->search( { user_account_id => $user->id, } )->delete;

    $self->add_log_no_user( $c, 'verify-email',
        {
            description => "Email address verified for new account",
            owner_id    => $user->id,
            guid        => $guid,
        },
    );

    $self->redirect_with_msg( $c, "/", "Email address verified, please login to continue." );
}

__PACKAGE__->meta->make_immutable;

1;
