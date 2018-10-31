package TauHead::Controller::System::Station;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub station : Chained('../system') : CaptureArgs(1) {
    my ( $self, $c, $slug ) = @_;

    my $system = $c->stash->{system};

    my $station = $c->model('DB')->resultset('Station')->find( { system_id => $system->id, slug => $slug } )
        or return $self->not_found($c);

    $self->add_breadcrumb( $c, [ $c->uri_for( '/system', $system->slug, 'station', $station->slug ), $station->name ] );

    $c->stash->{station} = $station;
}

sub view : PathPart('') : Chained('station') : Args(0) {
    my ( $self, $c ) = @_;

    my $system  = $c->stash->{system};
    my $station = $c->stash->{station};

    $c->stash->{areas} = $station->child_areas_sorted;

    $c->stash->{area_missions} = $c->model('DB')->resultset('Mission')->search(
        {
            'station.id' => $station->id,
        },
        {
            join => [
                { 'mission_areas' => { 'area' => 'station' } },
            ],
            distinct => 1,
            order_by => 'me.slug',
        }
    );

    $c->stash->{disqus_url} = $c->uri_for( '/system', $system->slug, 'station', $station->slug );
}

sub end : ActionClass('RenderView') { }

__PACKAGE__->meta->make_immutable;

1;
