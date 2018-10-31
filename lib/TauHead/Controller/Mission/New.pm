package TauHead::Controller::Mission::New;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);

    $c->check_any_user_role(qw( editor admin ));
}

sub mission_new : Path('/mission/new') : Args(0) : FormConfig { }

sub mission_new_FORM_NOT_VALID {
    my ( $self, $c ) = @_;

    $c->stash->{rest}
        = { errors => $c->stash->{form}->jquery_validation_errors_join('<br/>'),
        };
}

sub mission_new_FORM_VALID {
    my ( $self, $c ) = @_;

    my $form = $c->stash->{form};

    my $mission = $form->model->create;

    $self->add_log( $c, 'mission/add',
        {
            description => "Added a new Mission",
            mission_id  => $mission->id,
            slug        => $mission->slug,
            level       => $mission->level,
            mermaid     => $mission->mermaid,
        },
    );

    my $msg      = "New Mission added.";
    my $redirect = $c->uri_for( "/mission", $mission->slug, { mid => $c->set_status_msg($msg) } );

    $c->stash->{rest} = {
        ok       => 1,
        redirect => $redirect->as_string,
    };

    $c->detach;
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
