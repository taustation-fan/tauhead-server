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

    my @existing_links = $station->interstellar_links->all;
    my @other_slugs = map {
        ( $station->slug eq $_->station_a ) ? $_->station_b : $_->station_a;
    } @existing_links;
    $form->get_field('interstellar')->default(\@other_slugs);

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

    if ( $form->params->{interstellar} ) {
        my $links = $form->param_array('interstellar');
        my $link_rs = $c->model('DB')->resultset('InterstellarLink');
        my @existing_links = $station->interstellar_links->all;
        my @other_slugs = map {
            ( $station->slug eq $_->station_a ) ? $_->station_b : $_->station_a;
        } @existing_links;

        for my $target (@{ $links }) {
            if ( grep { $target eq $_ } @other_slugs ) {
                next;
            }
            $link_rs->create({
                station_a => $station->slug,
                station_b => $target,
            });
        }
        # remove any unchecked
        for my $link (@existing_links) {
            my $target_slug = ( $station->slug eq $link->station_a ) ? $link->station_b : $link->station_a;
            if ( grep { $target_slug eq $_ } @$links ) {
                next;
            }
            $link->delete;
        }
    }

    $self->add_log( $c, 'station/edit',
        {
            description  => "Edited a station",
            system_slug  => $system->slug,
            station_slug => $station->slug,
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
