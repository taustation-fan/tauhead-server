package TauHead::Controller::Admin::User::Enable;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub enable : Chained('../user') : Args(0) : FormConfig {
}

sub enable_FORM_NOT_SUBMITTED {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{view_user};
    my $form = $c->stash->{form};

    $form->model->default_values( $user );

    $form->process;
}

sub enable_FORM_NOT_VALID {
    my ( $self, $c ) = @_;

    $c->stash->{rest}
        = { errors => $c->stash->{form}->jquery_validation_errors_join('<br/>'),
        };
}

sub enable_FORM_VALID {
    my ( $self, $c ) = @_;

    my $user   = $c->stash->{view_user};
    my $form   = $c->stash->{form};
    my $reason = $form->param_value('reason');

    $user->update({
        disabled        => 0,
        disabled_reason => "",
    });

    my $msg      = "The account has been enabled.";
    my $redirect = $c->uri_for( "/admin/user", $user->id, { mid => $c->set_status_msg($msg) } );

    $c->stash->{rest} = {
        ok       => 1,
        redirect => $redirect->as_string,
    };

    $self->add_log( $c, 'admin/user/enable',
        {
            description    => "Enabled a disabled user account",
            owner_id       => $user->id,
            enabled_reason => $reason,
        },
    );

    $c->detach;
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
