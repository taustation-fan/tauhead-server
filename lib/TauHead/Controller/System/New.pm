package TauHead::Controller::System::New;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);

    $c->check_any_user_role(qw( editor admin ));
}

sub system_new : Path('/system/new') : Args(0) : FormConfig { }

sub system_new_FORM_NOT_VALID {
    my ( $self, $c ) = @_;

    $c->stash->{rest}
        = { errors => $c->stash->{form}->jquery_validation_errors_join('<br/>'),
        };
}

sub system_new_FORM_VALID {
    my ( $self, $c ) = @_;

    my $form = $c->stash->{form};

    my $system = $form->model->create;

    $self->add_log( $c, 'system/add',
        {
            description => "Added a new system",
            system_id   => $system->id,
        },
    );

    my $msg      = "New System added.";
    my $redirect = $c->uri_for( "/system", $system->slug, { mid => $c->set_status_msg($msg) } );

    $c->stash->{rest} = {
        ok       => 1,
        redirect => $redirect->as_string,
    };

    $c->detach;
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
