package TauHead::Controller::Item::Download;
use Moose;
use DBIx::Class::ResultClass::HashRefInflator;
use Cpanel::JSON::XS qw( encode_json );
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);
}

sub download : Chained('/') : Args(0) : FormConfig { }

sub download_FORM_NOT_VALID {
    my ( $self, $c ) = @_;

    $c->stash->{rest}
        = { errors => $c->stash->{form}->jquery_validation_errors_join('<br/>'),
        };
}

sub download_FORM_VALID {
    my ( $self, $c ) = @_;

    my $rs = $c->model('DB')->resultset('Item');
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');

    my @items = $rs->all;

    $self->add_log( $c, 'item/download',
        {
            description => "Item list downloaded",
        },
    );

    $c->stash->{rest} = {
        ok      => 1,
        message => "Download started",
    };

    $c->response->content_type('application/json');
    $c->response->header( 'Content-Disposition' => "attachment;filename='tauhead-items.json'" );
    $c->response->body( encode_json({ items=> \@items }));
    $c->detach;
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
