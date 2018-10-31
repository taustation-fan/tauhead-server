package TauHead::Controller::System::Station::Edit;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);

    $c->check_any_user_role(qw( editor admin ));
}

sub edit : Chained('../station') : Args(0) : FormConfig { }

sub edit_FORM_NOT_SUBMITTED {
    my ( $self, $c ) = @_;

    my $form    = $c->stash->{form};
    my $station = $c->stash->{station};

    $form->model->default_values($station);
}

sub edit_FORM_NOT_VALID {
    my ( $self, $c ) = @_;

    $c->stash->{rest}
        = { errors => $c->stash->{form}->jquery_validation_errors_join('<br/>'),
        };
}

sub edit_FORM_VALID {
    my ( $self, $c ) = @_;

    my $form    = $c->stash->{form};
    my $system  = $c->stash->{system};
    my $station = $c->stash->{station};

    $form->model->update($station);

    $self->add_log( $c, 'station/edit',
        {
            description => "Edited a station",
            system_id   => $system->id,
            station_id  => $station->id,
        },
    );

    my $msg      = "Changes saved.";
    my $redirect = $c->uri_for( "/system", $system->slug, "station", $station->slug, { mid => $c->set_status_msg($msg) } );

    $c->stash->{rest} = {
        ok       => 1,
        redirect => $redirect->as_string,
    };

    $c->detach;
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
