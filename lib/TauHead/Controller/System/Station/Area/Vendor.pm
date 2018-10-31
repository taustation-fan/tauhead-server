package TauHead::Controller::System::Station::Area::Vendor;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub vendor : Chained('../area') : CaptureArgs(1) {
    my ( $self, $c, $slug ) = @_;

    my $area  = $c->stash->{area};

    my $vendor = $area->find_related( 'vendors', { slug => $slug } )
        or return $self->not_found($c);

    $self->add_breadcrumb( $c, [ $c->uri_for( '/vendor', $vendor->slug ), $vendor->name ] );

    $c->stash->{vendor} = $vendor;
}

sub view : PathPart('') : Chained('vendor') : Args(0) {
    my ( $self, $c ) = @_;

    my $system  = $c->stash->{system};
    my $station = $c->stash->{station};
    my $area    = $c->stash->{area};
    my $vendor  = $c->stash->{vendor};

    $c->stash->{vendor_items} = $vendor->search_related(
        'vendor_items',
        undef,
        {
            prefetch => [ { 'item' => 'item_type' } ],
            order_by => 'item.slug',
        },
    );

    $c->stash->{disqus_url} = $c->uri_for( '/system', $system->slug, 'station', $station->slug, 'area', $area->slug, 'vendor', $vendor->slug );
}

sub end : ActionClass('RenderView') { }

__PACKAGE__->meta->make_immutable;

1;
