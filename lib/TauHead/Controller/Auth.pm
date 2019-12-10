package TauHead::Controller::Auth;
use Moose;
use DateTime;
use URI;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub login : Path('/login') : Args(0) : FormConfig {
    my ( $self, $c ) = @_;

    if ( $c->user_exists ) {
        my $target = $self->_default_landing_page( $c );

        $c->response->redirect( $target );
        $c->detach;
    }
}

sub login_FORM_NOT_SUBMITTED {
    my ( $self, $c ) = @_;

    my $form = $c->stash->{form};

    if ( my $uri = $c->request->param('return') ) {
        $uri = URI->new($uri);

        $form->default_values({
            forward => $uri->as_string,
        });
    }
}

sub login_FORM_VALID {
    my ( $self, $c ) = @_;

    my $form     = $c->stash->{form};
    my $username = $form->param_value('username');

    # basic checks before checking full authentication
    my $user = $c->model('DB')->resultset('UserAccount')->find( {
        username => $username,
    } );

    if ( !$user ) {
        $self->_set_default_login_error($c);

        $self->add_log_no_user( $c, 'login-failure/unknown-username', {
            description => 'Login failure - unknown username',
            username    => $username,
        } );

        $c->detach;
    }

    $self->check_email_confirmed( $c, $user );
    $self->check_not_disabled(    $c, $user );

    # check number of login failure attempts
    my $failed_attempts  = $user->related_resultset('login_failure')->count;
    my $allowed_attempts = $c->login_attempts_limit;

    if ( $failed_attempts >= $allowed_attempts ) {
        $self->add_log_no_user( $c, 'login-failure/limit-attempts', {
            owner_id         => $user->id,
            description      => 'Not allowing login - exceeded allowed number of attempts',
            failed_attempts  => $failed_attempts,
            allowed_attempts => $allowed_attempts,
        } );

        $c->stash->{rest} = {
            errors => {
                username => 'Too many failed attempts - account locked'
            },
            link => {
                field => 'username',
                text => 'Click here to unlock account',
                href => $c->uri_for( '/unlock-account', { prefill => $username } )->as_string,
            },
        };
        $c->detach;
    }

    # go ahead with full authentication
    my $ok = $c->authenticate(
        {   username        => $username,
            password_base64 => $form->param_value('password'),
        } );

    if ($ok) {
        $self->add_log( $c, 'login' );

        if ( my $uri = $form->param('forward') ) {

            $uri = URI->new( $form->param('forward') );

            # only use the supplied path + query
            # don't trust the schema / hostname
            $uri = $c->uri_for(
                $uri->path,
                {
                    $uri->query_form,
                },
            );

            $c->stash->{rest} = {
                ok => 1,
                redirect => $uri->as_string,
            };

            $c->detach;
        }

        my $target = $self->_default_landing_page( $c );

        $c->stash->{rest} = {
            ok       => 1,
            redirect => $target->as_string,
        };
    }
    else {
        $user->create_related( 'login_failure', {
            datetime => DateTime->now,
        } );

        $self->add_log_no_user( $c, 'login-failure/authentication', {
            description => 'Login failure',
            owner_id    => $user->id,
        } );

        $self->_set_default_login_error($c);
    }
}

sub _set_default_login_error {
    my ( $self, $c ) = @_;

    $c->stash->{rest} = {
        errors => {
            username => 'Incorrect username or password',
            password => 'Incorrect username or password',
        },
        password2text => 1,
    };
}

sub _default_landing_page {
    my ( $self, $c ) = @_;

    return $c->uri_for('/');
}

sub check_email_confirmed {
    my ( $self, $c, $user ) = @_;

    if ( $user->email_confirmed ) {
        return 1;
    }

    $self->add_log_no_user( $c, 'login-failure/email-not-confirmed', {
        owner_id    => $user->id,
        description => 'Not allowing login - email address not yet verified',
    } );

    my $msg = <<MSG;
You must first validate your email address by clicking on the link in the email sent to your registered address.
MSG

    $c->stash->{rest} = { errors => { username => $msg, }, };

    $c->detach;
}

sub check_not_disabled {
    my ( $self, $c, $user ) = @_;

    if ( ! $user->disabled ) {
        return 1;
    }

    $self->add_log_no_user( $c, 'login-failure/account-disabled', {
        owner_id    => $user->id,
        description => 'Not allowing login - account disabled',
    } );

    my $msg = <<MSG;
Your account has been disabled - you cannot login.
MSG

    $c->stash->{rest} = { errors => { username => $msg, }, };

    $c->detach;
}

sub logout : Global : Args(0) {
    my ( $self, $c ) = @_;

    if ( $c->user_exists ) {
        $self->add_log( $c, 'logout' );

        $c->logout;
    }

    $c->delete_session;

    $c->response->redirect( $c->uri_for('/') );
    $c->detach;
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
