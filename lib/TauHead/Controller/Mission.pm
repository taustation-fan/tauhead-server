package TauHead::Controller::Mission;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub mission : Chained('/') : CaptureArgs(1) {
    my ( $self, $c, $slug ) = @_;

    my $mission = $c->model('DB')->resultset('Mission')->find( { slug => $slug } )
        or return $self->not_found($c);

    $self->add_breadcrumb( $c, [ $c->uri_for( '/mission/list' ), 'Missions' ] );
    $self->add_breadcrumb( $c, [ $c->uri_for( '/mission', $mission->slug ), $mission->name ] );

    $c->stash->{mission} = $mission;
}

sub view : PathPart('') : Chained('mission') : Args(0) {
    my ( $self, $c ) = @_;

    my $mission = $c->stash->{mission};

    $c->stash->{disqus_url} = $c->uri_for( '/mission', $mission->slug );
}

sub flowchart : PathPart('flowchart') : Chained('mission') : Args(0) {
    my ( $self, $c ) = @_;

    my $mission = $c->stash->{mission};

    my @graphs = $mission->mermaid_graphs
        or return $self->not_found($c);

    $c->stash->{mermaid_graphs} = \@graphs;
}

sub end : ActionClass('RenderView') { }

__PACKAGE__->meta->make_immutable;

1;
