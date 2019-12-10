package TauHead::Controller::Unlock_Account;
use Moose;
use Data::GUID::URLSafe;
use MIME::Lite;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub send_email : Path('/unlock-account') : Args(0) : FormConfig {
    my ( $self, $c ) = @_;

    $self->logged_out_users_only($c);
}

sub send_email_FORM_NOT_SUBMITTED {
    my ( $self, $c ) = @_;

    my $form = $c->stash->{form};

    if ( my $username = $c->request->param('prefill') ) {
        $form->default_values({
            username => $username,
        });
    }
}

sub send_email_FORM_NOT_VALID {
    my ( $self, $c ) = @_;

    $c->stash->{rest}
        = { errors => $c->stash->{form}->jquery_validation_errors_join('<br/>'),
        };
}

sub send_email_FORM_VALID {
    my ( $self, $c ) = @_;

    $self->_send_email($c);

    $c->stash->{rest} = {
        ok      => 1,
        message => 'Email Sent! - it should be with you in a few minutes.',
        clear   => 1,
    };
}

sub _send_email : Private {
    my ( $self, $c ) = @_;

    my $user
        = $c->model('DB')->resultset('UserAccount')
        ->find( { username => $c->stash->{form}->param_value('username'), } )
            or return $self->not_found($c);

    my $guid = Data::GUID->new->as_base64_urlsafe;

    my $change_request = $user->create_related(
        'unlock_account_request',
        {   guid     => $guid,
            datetime => \"NOW()",
        } );

    my $txt = <<TXT;
Your account at TauHead has been locked due to excessive login failures.

To unlock your account, please click here: %s
TXT

    my $msg = MIME::Lite->new(
        From    => $c->system_email_address,
        To      => $user->email,
        Subject => 'TauHead: Unlock account',
        Data    => sprintf( $txt, $c->uri_for( '/unlock-account', $guid ), ),
    );

    $msg->send;

    $c->stash->{rest} = {
        ok      => 1,
        message => 'Email Sent!',
        clear   => 1,
    };

    $self->add_log_no_user( $c, 'unlock-account/send-email',
        {
            description => "Sent email to allow unlocking account after too many login failures",
            guid        => $guid,
            owner_id    => $user->id,
        },
    );
}

sub unlock_account : Path('/unlock-account') : Args(1) {
    my ( $self, $c, $guid ) = @_;

    $self->logged_out_users_only($c);

    my $reset
        = $c->model('DB')->resultset('UnlockAccountRequest')->find($guid);

    if ( !$reset ) {
        my $msg = "Unlock code no longer valid";

        $self->redirect_with_msg( $c, "/", $msg );
    }

    my $form  = $c->stash->{form};
    my $user  = $reset->user_account;

    $user->delete_related( 'login_failure' );

    $user->delete_related( 'unlock_account_request' );

    $self->add_log_no_user( $c, 'unlock-account',
        {
            description => "Account unlocked after email verification",
            owner_id    => $user->id,
            guid        => $guid,
        },
    );

    my $msg = "Your account has been unlocked - you can now login.";

    $self->redirect_with_msg( $c, "/", $msg );
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
