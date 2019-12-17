package TauHead::Controller::Search;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

our @SEARCH_FIELDS = (
    # ResultSet  # search fields           # order
    [ Item    => [qw( name description )], 'name' ],
    [ NPC     => [qw( name description )], 'name' ],
    [ Mission => [qw( name )], 'name' ],
    [ Vendor  => [qw( name )], 'name' ],
    [ Area    => [qw( name area_description_short area_description_long )], 'name' ],
    [ Station => [qw( name )], 'name' ],
    [ System  => [qw( name )], 'name' ],
);

sub search : Chained('/') : Args(0) {
    my ( $self, $c, $slug ) = @_;

    my $term = $c->request->param('query');

    if ( !$term || length($term) < 2) {
        $c->response->redirect( $c->uri_for('/') );
        $c->detach;
    }

    my $query = sprintf '%%%s%%', $term;
    my $model = $c->model('DB');
    my $total = 0;
    my @hits;

    for my $field (@SEARCH_FIELDS) {
        my ( $type, $cols, $order ) = @{ $field };

        my $rs = $model->resultset($type)->search(
            {
                -or => [
                    map { $_ => { 'ILIKE' => $query } } @$cols
                ],
            },
            {
                order_by => $order,
            },
        );

        my $count = $rs->count;

        if ($count) {
            $total += $count;
            push @hits, { name => $type, count => $count, rs => $rs };
        }
    }

    if ( 1 == $total ) {
        # redirect to single page
        my $rs  = $hits[0]->{rs};
        my $hit = $rs->first;

        $c->response->redirect( $hit->build_uri($c) );
        $c->detach;
    }

    $c->stash->{search_query} = $term;
    $c->stash->{total}        = $total;
    $c->stash->{hits}         = \@hits;
}

sub end : ActionClass('RenderView') { }

__PACKAGE__->meta->make_immutable;

1;
