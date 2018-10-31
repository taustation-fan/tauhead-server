package TauHead::Controller::Admin::User::Disable;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub disable : Chained('../user') : Args(0) : FormConfig {
}

sub disable_FORM_NOT_SUBMITTED {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{view_user};
    my $form = $c->stash->{form};

    $form->model->default_values( $user );

    $form->process;
}


sub disable_FORM_NOT_VALID {
    my ( $self, $c ) = @_;

    $c->stash->{rest}
        = { errors => $c->stash->{form}->jquery_validation_errors_join('<br/>'),
        };
}

sub disable_FORM_VALID {
    my ( $self, $c ) = @_;

    my $user   = $c->stash->{view_user};
    my $form   = $c->stash->{form};
    my $reason = $form->param_value('reason');

    $user->update({
        disabled        => 1,
        disabled_reason => $reason,
    });

    my $msg      = "The account has been disabled.";
    my $redirect = $c->uri_for( "/admin/user", $user->id, { mid => $c->set_status_msg($msg) } );

    $c->stash->{rest} = {
        ok       => 1,
        redirect => $redirect->as_string,
    };

    $self->add_log( $c, 'admin/user/disable',
        {
            description     => "Disabled user account",
            disabled_reason => $reason,
            owner_id        => $user->id,
        },
    );

    $c->detach;
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
