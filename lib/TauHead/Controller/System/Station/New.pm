package TauHead::Controller::System::Station::New;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);

    $c->check_any_user_role(qw( editor admin ));
}

sub station_new : PathPart('station/new') : Chained('../../system') : Args(0) : FormConfig { }

sub station_new_FORM_NOT_VALslug {
    my ( $self, $c ) = @_;

    $c->stash->{rest}
        = { errors => $c->stash->{form}->jquery_validation_errors_join('<br/>'),
        };
}

sub station_new_FORM_VALID {
    my ( $self, $c ) = @_;

    my $form   = $c->stash->{form};
    my $system = $c->stash->{system};

    $form->add_valid( system_slug => $system->slug );

    my $station = $form->model->create;

    my @links = $form->param_list('interstellar');
    if ( @links ) {
        my $link_rs = $c->model('DB')->resultset('InterstellarLink');
        for my $other (@links) {
            $link_rs->create({
                station_a => $station->slug,
                station_b => $other,
            });
        }
    }

    $self->add_log( $c, 'station/add',
        {
            description  => "Added a new station",
            system_slug  => $system->slug,
            station_slug => $station->slug,
        },
    );

    my $msg      = "New Station added.";
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
