package TauHead::Controller::API::Data_Gatherer;
use Moose;
use JSON::MaybeXS qw( encode_json );
use Try::Tiny;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    # Check user logged-in
    if ( !$c->user_exists ) {
        $c->stash->{rest} = {
            error     => "Not logged-in to " . $c->config->{name},
            login_url => $c->uri_for( "/login" ),
        };
        return 0;
    }

    # Check there are no file-uploads
    my $uploads = $c->request->uploads;

    if ( $uploads && keys %$uploads ) {
        $c->stash->{rest} = {
            error => "File uploads not allowed",
        };
        return 0;
    }

    # Verify data method
    my $params = $c->request->body_parameters;
    my $method = delete $params->{method};
    my $max_method =
        $c->model('DB')->resultset('DataGatherer')->result_source->column_info('method')->{size};

    if ( !defined($method) || !length($method) || length($method) > $max_method ) {
        $c->stash->{rest} = {
            error => "Bad 'method' parameter",
        };
        return 0;
    }

    my $json;
    try {
        $json = encode_json( $params );
    };

    if ( !$json ) {
        $c->stash->{rest} = {
            error => "Failed to process uploaded data",
        };
        return 0;
    }

    # Verify upload size
    my $upload_limit = 1024 * 1024; # 1MB

    if ( length($json) > $upload_limit ) {
        $c->stash->{rest} = {
            error => "Uploaded data exceeds allowed size limit",
        };
        return 0;
    }

    $c->stash->{data_gatherer_method} = $method;
    $c->stash->{data_gatherer_json}   = $json;

    return 1;
}

sub index : Path('/api/data_gatherer') : Args(0) {
    my ( $self, $c ) = @_;

    my $method = $c->stash->{data_gatherer_method};
    my $json   = $c->stash->{data_gatherer_json};

    try {
        $c->user->obj->create_related(
            'data_gatherer',
            {
                claimed  => 0,
                held     => 0,
                complete => 0,
                method   => $method,
                json     => $json,
                datetime_created => \"NOW()",
                datetime_updated => \"NOW()",
            },
        );

        $c->stash->{rest} = {
            ok => 1,
        };
    }
    catch {
        $c->stash->{rest} = {
            error => "Failed to store uploaded data",
        };
    };
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
