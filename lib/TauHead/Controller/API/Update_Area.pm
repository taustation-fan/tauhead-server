package TauHead::Controller::API::Update_Area;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);

    $c->check_any_user_role(qw( api admin ));
}

sub index : Path('/api/update_area') : Args(0) : FormConfig {}

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

     # find area
     my $area = $station->find_related(
        'areas',
        {
            slug => $form->param_value('slug'),
        }
     );

     if ( !$area ) {
         return $self->invalidate_form( $c, "slug", "Area with this slug not found in this Station" );
     }

     if ( $area->parent_area_id ) {
         return $self->invalidate_form( $c, "slug", "This Area has a parent_area_id - use \"Update Sub-Area\" instead" );
     }

     if ( $form->valid('submit') ) {
         $form->model->update( $area );

         my $msg      = "Area updated.";
         my $redirect = $c->uri_for( "/system", $system->slug, "station", $station->slug, "area", $area->slug, { mid => $c->set_status_msg($msg) } );

         $c->stash->{rest} = {
             ok       => 1,
             redirect => $redirect->as_string,
         };

         $self->add_log( $c, 'api/update_area',
             {
                 description => "API Updated Area",
                 area_id     => $area->id,
             },
         );

         $c->detach;
     }
     else {
         # highlight differences
         for my $key (qw( name aka bg_img content_img content_side_img hero_img other_img area_description_short area_description_long )) {
             my $orig_value = $area->$key;
             my $new_value  = $form->param_value($key);

             if ( $orig_value ne $new_value ) {
                 $form->get_field({ name => $key })
                     ->add_container_attrs({ class => 'alert-danger' })
                     ->comment("Changed: was '$orig_value'");
             }
         }
     }
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
