package TauHead::Controller::System::Station::Area::Vendor::Delete;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);

    $c->check_any_user_role(qw( editor admin ));
}

sub delete : Chained('../vendor') : Args(0) : FormConfig { }

sub delete_FORM_NOT_SUBMITTED {
    my ( $self, $c ) = @_;

    my $form   = $c->stash->{form};
    my $vendor = $c->stash->{vendor};
}

sub delete_FORM_NOT_VALID {
    my ( $self, $c ) = @_;

    $c->stash->{rest}
        = { errors => $c->stash->{form}->jquery_validation_errors_join('<br/>'),
        };
}

sub delete_FORM_VALID {
    my ( $self, $c ) = @_;

    my $form    = $c->stash->{form};
    my $system  = $c->stash->{system};
    my $station = $c->stash->{station};
    my $area    = $c->stash->{area};
    my $vendor  = $c->stash->{vendor};

    $vendor->delete;

    $self->add_log( $c, 'vendor/delete',
        {
            description => "Deleted a Vendor",
            vendor_id   => $vendor->id,
        },
    );

    my $msg      = "Vendor deleted.";
    my $redirect = $c->uri_for(
        '/system', $system->slug, 'station', $station->slug, 'area', $area->slug,
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
