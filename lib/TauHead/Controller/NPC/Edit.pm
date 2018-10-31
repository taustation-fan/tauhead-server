package TauHead::Controller::NPC::Edit;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);

    $c->check_any_user_role(qw( editor admin ));
}

sub edit : Chained('../npc') : Args(0) : FormConfig { }

sub edit_FORM_NOT_SUBMITTED {
    my ( $self, $c ) = @_;

    my $form = $c->stash->{form};
    my $npc  = $c->stash->{npc};

    $form->model->default_values($npc);
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
    my $npc  = $c->stash->{npc};

    $form->model->update( $npc );

    $self->add_log( $c, 'npc/edit',
        {
            description => "Added a new NPC",
            npc_id      => $npc->id,
        },
    );

    my $msg      = "Changes saved.";
    my $redirect = $c->uri_for( "/npc", $npc->slug, { mid => $c->set_status_msg($msg) } );

    $c->stash->{rest} = {
        ok       => 1,
        redirect => $redirect->as_string,
    };

    $c->detach;
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
