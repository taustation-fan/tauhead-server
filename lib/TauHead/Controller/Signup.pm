package TauHead::Controller::Signup;
use Moose;
use Data::GUID::URLSafe;
use MIME::Lite;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub send_email : Path('') : Args(0) : FormConfig {
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

    my $form = $c->stash->{form};
    my $db   = $c->model('DB');

    my $password_base64
        = $self->generate_password_base64( $c, $form->param_value('password') );

    my $password_type
        = $c->config->{'Plugin::Authentication'}{default}{credential}
        {password_hash_type};

    my $user = $db->resultset('User')->create(
        {   username        => $form->param_value('username'),
            email           => $form->param_value('email'),
            password_base64 => $password_base64,
            password_type   => $password_type,
        } );

    #$user->apply_default_preferences;

    $self->send_email_verifier( $c, $user );

    $c->stash->{rest} = {
        ok => 1,
        message =>
            'Verification Email Sent! - it should be with you in a few minutes.',
        clear => 1,
    };
}

sub send_email_verifier {
    my ( $self, $c, $user ) = @_;

    my $guid = Data::GUID->new->as_base64_urlsafe;

    my $change_request = $user->create_related(
        'verify_email_request',
        {   guid     => $guid,
            datetime => \"NOW()",
        } );

    my $txt = <<TXT;
Your email address has been used to sign up for an account at TauTest

To verify your email address, please click here:
%s

If you don't want an account, please just delete this message,
we won't contact you again.
TXT

    my $msg = MIME::Lite->new(
        From    => $c->system_email_address,
        To      => $user->email,
        Subject => 'TauHead: Verify email address for new account',
        Data    => sprintf( $txt, $c->uri_for( '/verify-email', $guid ), ),
    );

    $msg->send;

    $self->add_log_no_user( $c, 'signup',
        {
            description => "Verification email sent for new account",
            guid        => $guid,
            owner_id    => $user->id,
        },
    );
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
