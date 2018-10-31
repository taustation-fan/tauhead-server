package TauHead::Controller::Mission::Edit;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);

    $c->check_any_user_role(qw( editor admin ));
}

sub edit : Chained('../mission') : Args(0) : FormConfig { }

sub edit_FORM_NOT_SUBMITTED {
    my ( $self, $c ) = @_;

    my $form    = $c->stash->{form};
    my $mission = $c->stash->{mission};

    $form->model->default_values($mission);
}

sub edit_FORM_NOT_VALID {
    my ( $self, $c ) = @_;

    $c->stash->{rest}
        = { errors => $c->stash->{form}->jquery_validation_errors_join('<br/>'),
        };
}

sub edit_FORM_VALID {
    my ( $self, $c ) = @_;

    my $form = $c->stash->{form};
    my $mission  = $c->stash->{mission};

    $form->model->update( $mission );

    $self->add_log( $c, 'mission/edit',
        {
            description => "Added a new Mission",
            mission_id  => $mission->id,
            level       => $mission->level,
            slug        => $mission->slug,
            mermaid     => $mission->mermaid,
        },
    );

    my $msg      = "Changes saved.";
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
