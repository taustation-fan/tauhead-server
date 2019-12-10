package TauHead::Controller::Change_Email;
use Moose;
use Data::GUID::URLSafe;
use MIME::Lite;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);
}

sub send_email : Path('/change-email') : Args(0) : FormConfig {
}

sub send_email_FORM_NOT_VALID {
    my ( $self, $c ) = @_;

    $c->stash->{rest}
        = { errors => $c->stash->{form}->jquery_validation_errors_join('<br/>'),
        };
}

sub send_email_FORM_VALID {
    my ( $self, $c ) = @_;

    my $form    = $c->stash->{form};
    my $user_rs = $c->user->obj;

    # check current password first

    my $password_base64
        = $self->generate_password_base64( $c, $form->param_value('password') );

    if ( $password_base64 ne $user_rs->password_base64 ) {
        $c->stash->{rest} = {
            errors => {
                password => 'Incorrect Password',
            },
            password2text => 1,
        };

        $c->detach;
    }

    # ok, send verification email

    $self->_send_email($c);

    my $msg = "Verification email sent - please click the link in the email to finish updating your address.";

    $c->stash->{rest} = {
        ok       => 1,
        redirect => $c->uri_for(
            "/account",
            { mid => $c->set_status_msg($msg) },
        )->as_string,
    };
}

sub _send_email : Private {
    my ( $self, $c ) = @_;

    my $user = $c->user->obj;
    my $guid = Data::GUID->new->as_base64_urlsafe;

    my $change_request = $user->create_related(
        'email_change_request',
        {   guid     => $guid,
            datetime => \"NOW()",
            email    => $c->stash->{form}->param_value('email'),
        } );

    my $txt = <<TXT;
We received a request to reset the email address for your account at TauHead

Please click here: %s

If you didn't request the change, someone may have access to your account,
in which case we recommend changing your password as soon as possible.
TXT

    my $msg = MIME::Lite->new(
        From    => $c->system_email_address,
        To      => $user->email,
        Subject => 'TauHead: Change email address',
        Data    => sprintf( $txt, $c->uri_for( '/change-email', $guid ), ),
    );

    $self->add_log( $c, 'change-email/send-email',
        {
            description => "Sent verification email for email change request",
            guid        => $guid,
        },
    );
    $msg->send;
}

sub change_email : Path('/change-email') : Args(1) {
    my ( $self, $c, $guid ) = @_;

    my $change_request
        = $c->model('DB')->resultset('EmailChangeRequest')->find($guid);

    if ( !$change_request ) {
        $self->redirect_with_msg( $c, "Code no longer valid" );
    }

    $change_request->user_account->update({
        email => $change_request->email,
    });

    $change_request->delete;

    $self->add_log( $c, 'change-email',
        {
            description => "Email address change confirmed",
            guid        => $guid,
        },
    );

    $self->redirect_with_msg( $c, "Your email address has been changed." );
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
