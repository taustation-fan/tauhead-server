package TauHead::Controller::API::Update_Station_Details;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);

    $c->check_any_user_role(qw( api admin ));
}

sub index : Path('/api/update_station_details') : Args(0) : FormConfig {}

sub index_FORM_NOT_VALID {
    my ( $self, $c ) = @_;
    $c->log->warn("input_FORM_NOT_VALID");

    $c->stash->{rest}
        = { errors => $c->stash->{form}->jquery_validation_errors_join('<br/>')};
}

sub index_FORM_VALID {
    my ( $self, $c ) = @_;
    $c->log->warn("input_FORM_VALID");

    my $form   = $c->stash->{form};
    my $schema = $c->model('DB');

    # find system
    my $system_name = $form->param_value('system');
    my $system = $schema->resultset('System')->find( { name => $system_name } )
        or return $self->invalidate_form( $c, 'system', 'System not found' );

    # find station
     my $station_name = $form->param_value('station');
     my $station = $schema->resultset('Station')->find({
         system_id => $system->id,
         name      => $station_name,
     }) or return $self->invalidate_form( $c, 'station', 'Station not found' );

     if ( $form->valid('submit') ) {
         $form->model->update( $station );

         my $msg      = "Station updated.";
         my $redirect = $c->uri_for( "/system", $system->slug, "station", $station->slug, { mid => $c->set_status_msg($msg) } );

         $c->stash->{rest} = {
             ok       => 1,
             redirect => $redirect->as_string,
         };

         $self->add_log( $c, 'api/update_station_details',
             {
                 description => "API Updated Station Details",
                 station_id  => $station->id,
             },
         );

         $c->detach;
     }
     else {
         # display difference
         for my $key (qw( affiliation level law_level orwellian_level )) {
             my $new_value = $form->param_value($key);
             if ( $new_value ne $station->$key ) {
                 $form->get_field({ name => $key })
                     ->add_attrs({ class => 'alert-danger' })
                     ->comment(sprintf("Changed: was '%s'", $station->$key))
             }
         }
     }
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
