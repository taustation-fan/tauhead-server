package TauHead::Controller::Reset_Password;
use Moose;
use Data::GUID::URLSafe;
use MIME::Lite;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub send_email : Path('/reset-password') : Args(0) : FormConfig {
    my ( $self, $c ) = @_;

    $self->logged_out_users_only($c);
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
        = $c->model('DB')->resultset('User')
        ->find( { username => $c->stash->{form}->param_value('username'), } )
            or return $self->not_found($c);

    my $guid = Data::GUID->new->as_base64_urlsafe;

    my $change_request = $user->create_related(
        'password_change_request',
        {   guid     => $guid,
            datetime => \"NOW()",
        } );

    my $txt = <<TXT;
We received a request to reset your password for your account at TauHead

Please click here: %s

If you don't want to reset your password, please just delete this
message.
TXT

    my $msg = MIME::Lite->new(
        From    => $c->system_email_address,
        To      => $user->email,
        Subject => 'TauHead: Reset password',
        Data    => sprintf( $txt, $c->uri_for( '/reset-password', $guid ), ),
    );

    $msg->send;

    $c->stash->{rest} = {
        ok      => 1,
        message => 'Email Sent!',
        clear   => 1,
    };

    $self->add_log_no_user( $c, 'reset-password/send-email',
        {
            description => "Sent verification email for password reset request",
            guid        => $guid,
            owner_id    => $user->id,
        },
    );
}

sub reset_password : Path('/reset-password') : Args(1) : FormConfig {
    my ( $self, $c, $guid ) = @_;

    $self->logged_out_users_only($c);

    my $reset
        = $c->model('DB')->resultset('PasswordChangeRequest')->find($guid);
    if ( !$reset ) {
        $c->stash->{error} = 'Reset code no longer valid';
        $c->detach;
    }

    $c->stash->{reset_rs} = $reset;

    return;
}

sub reset_password_FORM_NOT_SUBMITTED {
    my ( $self, $c, $guid ) = @_;

    my $reset   = $c->stash->{reset_rs};
    my $form    = $c->stash->{form};
    my $element = $form->get_field( { name => 'username' } );

    $element->default( $reset->user->username );
    $form->process;
}

sub reset_password_FORM_NOT_VALID {
    my ( $self, $c, $guid ) = @_;

    $c->stash->{rest}
        = { errors => $c->stash->{form}->jquery_validation_errors_join('<br/>'),
        };
}

sub reset_password_FORM_VALID {
    my ( $self, $c, $guid ) = @_;

    $self->logged_out_users_only($c);

    my $reset  = $c->stash->{reset_rs};
    my $form   = $c->stash->{form};
    my $passwd = $form->param_value('password');
    my $user   = $reset->user;

    $passwd = $self->generate_password_base64( $c, $passwd );

    $user->password_base64($passwd);
    $user->update;

    $c->model('DB')->resultset('PasswordChangeRequest')
        ->search( { user_id => $user->id, } )->delete;

    $c->stash->{rest} = {
        ok       => 1,
        redirect => $c->uri_for(
            '/',
            {   mid => $c->set_status_msg(
                    'Your password has been reset - you can now login.'),
            }
        )->as_string,
    };

    $self->add_log_no_user( $c, 'reset-password',
        {
            description => "Password changed after email verification",
            owner_id    => $user->id,
            guid        => $guid,
        },
    );
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
