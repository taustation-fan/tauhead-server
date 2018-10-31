package TauHead::Controller::NPC;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub npc : Chained('/') : CaptureArgs(1) {
    my ( $self, $c, $slug ) = @_;

    my $npc = $c->model('DB')->resultset('NPC')->find( { slug => $slug } )
        or return $self->not_found($c);

    $self->add_breadcrumb( $c, [ $c->uri_for( '/npc/list' ), 'NPCs' ] );
    $self->add_breadcrumb( $c, [ $c->uri_for( '/npc', $npc->slug ), $npc->name ] );

    $c->stash->{npc} = $npc;
}

sub view : PathPart('') : Chained('npc') : Args(0) {
    my ( $self, $c ) = @_;

    my $npc = $c->stash->{npc};

    $c->stash->{disqus_url} = $c->uri_for( '/npc', $npc->slug );
}

sub end : ActionClass('RenderView') { }

__PACKAGE__->meta->make_immutable;

1;
