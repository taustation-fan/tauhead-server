package TauHead::Controller::System::Station::Area::New;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);

    $c->check_any_user_role(qw( editor admin ));
}

sub area_new : PathPart('area/new') : Chained('../../station') : Args(0) : FormConfig { }

sub area_new_FORM_NOT_VALID {
    my ( $self, $c ) = @_;

    $c->stash->{rest}
        = { errors => $c->stash->{form}->jquery_validation_errors_join('<br/>'),
        };
}

sub area_new_FORM_VALID {
    my ( $self, $c ) = @_;

    my $form    = $c->stash->{form};
    my $system  = $c->stash->{system};
    my $station = $c->stash->{station};

    $form->add_valid( station_id => $station->id );

    my $area = $form->model->create;

    $self->add_log( $c, 'area/add',
        {
            description => "Added a new area",
            system_id   => $system->id,
            station_id  => $station->id,
            area_id     => $area->id,
        },
    );

    my $msg      = "New Area added.";
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
