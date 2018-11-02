package TauHead::Controller::API::Add_Area;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);

    $c->check_any_user_role(qw( api_update_area api admin ));
}

sub index : Path('/api/add_area') : Args(0) : FormConfig {}

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

     # area already exists?
     for my $name (qw( name aka slug )) {
         my $value = $form->param_value($name);

         if ( $station->count_related( 'areas', { $name => $value } ) ) {
             return $self->invalidate_form( $c, $name, ucfirst($name)." already exists" );
         }
    }

     if ( $form->valid('submit') ) {
         $form->add_valid( station_id => $station->id );

         my $area = $form->model->create;

         my $msg      = "New Area added.";
         my $redirect = $c->uri_for( "/system", $system->slug, "station", $station->slug, "area", $area->slug, { mid => $c->set_status_msg($msg) } );

         $c->stash->{rest} = {
             ok       => 1,
             redirect => $redirect->as_string,
         };

         $self->add_log( $c, 'api/add_area',
             {
                 description => "API Added Area",
                 area_id     => $area->id,
             },
         );

         $c->detach;
     }
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
