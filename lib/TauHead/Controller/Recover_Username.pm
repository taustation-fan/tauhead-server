package TauHead::Controller::Recover_Username;
use Moose;
use MIME::Lite;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub send_email : Path('/recover-username') : Args(0) : FormConfig {
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
        = $c->model('DB')->resultset('UserAccount')
        ->find( { email => $c->stash->{form}->param_value('email'), } )
            or return $self->not_found($c);

    my $txt = <<TXT;
We received a request to recover your username for your account at TauHead

Your TauHead username is '%s'
You can login here: %s
TXT

    my $msg = MIME::Lite->new(
        From    => $c->system_email_address,
        To      => $user->email,
        Subject => 'TauHead: Recover username',
        Data    => sprintf( $txt, $user->username, $c->uri_for('/'), ),
    );

    $msg->send;

    $self->add_log_no_user( $c, 'recover-username',
        {
            description => "Sent username to email address on file",
            owner_id    => $user->id,
        },
    );
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
