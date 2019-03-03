package TauHead::Controller::System::Station::Area::Edit;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);

    $c->check_any_user_role(qw( editor admin ));
}

sub edit : Chained('../area') : Args(0) : FormConfig { }

sub edit_FORM_NOT_SUBMITTED {
    my ( $self, $c ) = @_;

    my $form = $c->stash->{form};
    my $area = $c->stash->{area};

    $form->model->default_values($area);
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
    my $area    = $c->stash->{area};

    $form->model->update($area);

    $self->add_log( $c, 'station/edit',
        {
            description  => "Edited an area",
            system_slug  => $system->slug,
            station_slug => $station->slug,
            area_id      => $area->id,
        },
    );

    my $msg      = "Changes saved.";
    my $redirect = $c->uri_for( "/system", $system->slug, "station", $station->slug, "area", $area->slug, { mid => $c->set_status_msg($msg) } );

    $c->stash->{rest} = {
        ok       => 1,
        redirect => $redirect->as_string,
    };

    $c->detach;
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
