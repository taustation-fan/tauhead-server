package TauHead::Controller::System::Station::Area::Vendor::Edit;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);

    $c->check_any_user_role(qw( editor admin ));
}

sub edit : Chained('../vendor') : Args(0) : FormConfig { }

sub edit_FORM_NOT_SUBMITTED {
    my ( $self, $c ) = @_;

    my $form   = $c->stash->{form};
    my $vendor = $c->stash->{vendor};

    $form->model->default_values($vendor);
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
    my $vendor  = $c->stash->{vendor};

    $form->model->update( $vendor );

    $self->add_log( $c, 'vendor/edit',
        {
            description => "Added a new Vendor",
            vendor_id   => $vendor->id,
        },
    );

    my $msg      = "Changes saved.";
    my $redirect = $c->uri_for(
        '/system', $system->slug, 'station', $station->slug, 'area', $area->slug, 'vendor', $vendor->slug,
        { mid => $c->set_status_msg($msg) }
    );

    $c->stash->{rest} = {
        ok       => 1,
        redirect => $redirect->as_string,
    };

    $c->detach;
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
