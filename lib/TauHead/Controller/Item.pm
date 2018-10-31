package TauHead::Controller::Item;
use Moose;
use Cpanel::JSON::XS qw( encode_json );
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub item : Chained('/') : CaptureArgs(1) {
    my ( $self, $c, $slug ) = @_;

    my $item = $c->model('DB')->resultset('Item')->find( { slug => $slug } )
        or return $self->not_found($c);

    $c->stash->{item} = $item;
}

sub view : PathPart('') : Chained('item') : Args(0) {
    my ( $self, $c ) = @_;

    my $item = $c->stash->{item};

    $c->stash->{disqus_url} = $c->uri_for( '/item', $item->slug );
}

sub download : Path('/item/download') : Args(0) : FormConfig {
    my ( $self, $c ) = @_;

    $self->require_login($c);
}

sub download_FORM_NOT_VALID {
    my ( $self, $c ) = @_;

    $c->stash->{rest}
        = { errors => $c->stash->{form}->jquery_validation_errors_join('<br/>'),
        };
}

sub download_FORM_VALID {
    my ( $self, $c ) = @_;

    my $rs = $c->model('DB')->resultset('Item');
    my @items;

    while ( my $row = $rs->next ) {
        my %item;

        for my $cv ( @{ $row->export_col_vals } ) {
            $item{ $cv->{name} } = $cv->{value};
        }

        for my $comp (qw( armor medical mod weapon )) {
            my $method = "item_component_$comp";
            if ( my $rel = $row->$method ) {
                for my $cv ( @{ $rel->export_col_vals } ) {
                    $item{$method}{ $cv->{name} } = $cv->{value};
                }
            }
        }

        push @items, \%item;
    }

    $self->add_log( $c, 'item/download',
        {
            description => "Item list downloaded",
        },
    );

    $c->response->content_type('application/json');
    $c->response->header( 'Content-Disposition' => "attachment; filename=tauhead-items.json" );
    $c->response->body( encode_json({ items=> \@items }));
    $c->detach;
}

sub end : ActionClass('RenderView') { }

__PACKAGE__->meta->make_immutable;

1;
