package TauHead::Controller::System;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub system : Chained('/') : CaptureArgs(1) {
    my ( $self, $c, $slug ) = @_;

    my $system = $c->model('DB')->resultset('System')->find( { slug => $slug } )
        or return $self->not_found($c);

    $self->add_breadcrumb( $c, [ $c->uri_for( '/system/list' ), 'Systems' ] );
    $self->add_breadcrumb( $c, [ $c->uri_for( '/system', $system->slug ), $system->name ] );

    $c->stash->{system} = $system;
}

sub view : PathPart('') : Chained('system') : Args(0) {
    my ( $self, $c ) = @_;

    my $system = $c->stash->{system};

    $c->stash->{stations} = $system->stations_sorted;

    $c->stash->{disqus_url} = $c->uri_for( '/system', $system->slug );
}

sub end : ActionClass('RenderView') { }

__PACKAGE__->meta->make_immutable;

1;
