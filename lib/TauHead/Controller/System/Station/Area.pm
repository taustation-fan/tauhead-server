package TauHead::Controller::System::Station::Area;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub area : Chained('../station') : CaptureArgs(1) {
    my ( $self, $c, $slug ) = @_;

    my $system  = $c->stash->{system};
    my $station = $c->stash->{station};

    my $area = $c->model('DB')->resultset('Area')->find( { station_slug => $station->slug, slug => $slug } )
        or return $self->not_found($c);

    if ( my $parent = $area->parent_area ) {
        $self->add_breadcrumb( $c, [ $c->uri_for( '/system', $system->slug, 'station', $station->slug, 'area', $parent->slug ), $parent->name ] );
    }
    $self->add_breadcrumb( $c, [ $c->uri_for( '/system', $system->slug, 'station', $station->slug, 'area', $area->slug ), $area->name ] );

    $c->stash->{area} = $area;
}

sub view : PathPart('') : Chained('area') : Args(0) {
    my ( $self, $c ) = @_;

    my $system  = $c->stash->{system};
    my $station = $c->stash->{station};
    my $area     = $c->stash->{area};

    $c->stash->{disqus_url} = $c->uri_for( '/system', $system->slug, 'station', $station->slug, 'area', $area->slug );
}

sub end : ActionClass('RenderView') { }

__PACKAGE__->meta->make_immutable;

1;
