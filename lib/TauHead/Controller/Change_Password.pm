package TauHead::Controller::Change_Password;
use Moose;
use Data::GUID::URLSafe;
use MIME::Lite;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);
}

sub change_password : Path('/change-password') : Args(0) : FormConfig {
}

sub change_password_FORM_NOT_VALID {
    my ( $self, $c ) = @_;

    $c->stash->{rest}
        = { errors => $c->stash->{form}->jquery_validation_errors_join('<br/>'),
        };
}

sub change_password_FORM_VALID {
    my ( $self, $c ) = @_;

    my $form    = $c->stash->{form};
    my $db      = $c->model('DB');
    my $user_rs = $c->user->obj;

    # check current password first

    my $current_password_base64
        = $self->generate_password_base64( $c, $form->param_value('current_password') );

    if ( $current_password_base64 ne $user_rs->password_base64 ) {
        $c->stash->{rest} = {
            errors => {
                current_password => 'Incorrect Password',
            },
        };
        
        $c->detach;
    }

    # ok, update new password

    my $password_base64
        = $self->generate_password_base64( $c, $form->param_value('password') );

    my $password_type
        = $c->config->{'Plugin::Authentication'}{default}{credential}
        {password_hash_type};

    $user_rs->update(
        {   password_base64 => $password_base64,
            password_type   => $password_type,
        } );

    $self->send_email_password_changed( $c, $user_rs );

    my $msg = "Password changed.";

    $self->add_log( $c, 'password-changed' );

    $c->stash->{rest} = {
        ok => 1,
        redirect => $c->uri_for(
            "/account",
            { mid => $c->set_status_msg($msg) },
        )->as_string,
    };
}

sub send_email_password_changed {
    my ( $self, $c, $user ) = @_;

    my $body = <<BODY;
Your TauHead password has been changed.
BODY

    my $msg = MIME::Lite->new(
        From    => $c->system_email_address,
        To      => $user->email,
        Subject => 'TauHead: Your password has been changed.',
        Data    => $body,
    );

    $msg->send;
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
