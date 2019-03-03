package TauHead::BaseController;
use Moose;

use Cpanel::JSON::XS;
use Data::GUID::URLSafe;
use DateTime;
use MIME::Lite;
use Storable qw( nfreeze );
use Try::Tiny;
use TauHead::Util qw( html2text );
use URI;
use URI::QueryParam;

extends 'Catalyst::Controller::HTML::FormFu';

__PACKAGE__->config(
    default   => 'text/html',
    stash_key => 'rest',
    map       => {
        'text/html'        => [ 'View', 'HTML' ],
        'application/json' => 'JSON',
    },
);

sub not_found {
    my ( $self, $c ) = @_;

    $c->response->status(404);

    return $c->go( 'TauHead::Controller::Root', 'default' );
}

sub generate_password_base64 {
    my ( $self, $c, $password ) = @_;

    my $config    = $c->config->{'Plugin::Authentication'}{default}{credential};
    my $hash_type = $config->{password_hash_type};
    my $pre_salt  = $config->{password_pre_salt};
    my $post_salt = $config->{password_post_salt};

    my $digest = Digest->new($hash_type);
    $digest->add($pre_salt);
    $digest->add($password);
    $digest->add($post_salt);

    my $b64 = $digest->clone->b64digest;

    return $b64;
}

sub logged_out_users_only {
    my ( $self, $c ) = @_;

    if ( $c->user_exists ) {
        $c->response->redirect( $c->uri_for('/') );
        $c->detach;
    }
}

sub add_log {
    my ( $self, $c, $action, $data ) = @_;

    my %log = (
        datetime   => DateTime->now,
        ip_address => $c->request->address,
        action     => $action,
    );

    $self->_add_log_data( \%log, $data );
    $self->_add_log_form( $c, \%log );

    try {
        $c->user->obj->create_related( 'logs', \%log );
    }
    catch {
        $c->log->error( "add_log threw error: $_" );
    };
}

sub add_log_no_user {
    my ( $self, $c, $action, $data ) = @_;

    my %log = (
        datetime   => DateTime->now,
        ip_address => $c->request->address,
        action     => $action,
    );

    $self->_add_log_data( \%log, $data );
    $self->_add_log_form( $c, \%log );

    try {
        $c->model('DB')->resultset('Log')->create( \%log );
    }
    catch {
        $c->log->error( "add_log_no_user threw error: $_" );
    };
}

sub _add_log_data {
    my ( $self, $log, $data ) = @_;

    return if !defined $data;

    my @real_cols = qw(
        owner_id
        guid
    );

    # shallow-copy $data
    %$data = %$data;

    for my $col (@real_cols) {
        if ( exists $data->{$col} ) {
            $log->{$col} = delete $data->{$col};
        }
    }

    if ( %$data ) {
        $log->{data} = $data;
    }

    return;
}

sub _add_log_form {
    my ( $self, $c, $log ) = @_;

    return if exists $log->{data}{form_params};

    return if !exists $c->stash->{form};

    my $form = $c->stash->{form};

    return if ! $form->submitted_and_valid;

    try {
        $log->{data}{form_params} = encode_json( $form->params );
    }
    catch {
        $c->log->error( "_add_log_form threw error: $_" );
    };

    return;
}

sub redirect_with_msg {
    my $self = shift;
    my $c    = shift;

    my $msg = pop;
    my @url = @_;

    # allow missing url

    if ( !@url ) {
        @url = ("/");
    }

    # add missing period at end of message

    if ( "." ne substr $msg, -1, 1 ) {
        $msg .= ".";
    }

    $c->response->redirect(
        $c->uri_for(
            @url,
            { mid => $c->set_status_msg($msg) },
        ),
    );

    $c->detach;
}

sub require_login {
    my ( $self, $c ) = @_;

    return 1 if $c->user_exists;

    my $return = $c->request->uri->clone;

    if ( 'POST' eq $c->req->method ) {
        my $guid = Data::GUID->new->as_base64_urlsafe;

        $c->session->{"restore_$guid"} = nfreeze( $c->req->params );

        $return->query_param( restore => $guid );
    }

    $c->response->redirect(
        $c->uri_for(
            "/login",
            {
                return => $return->as_string,
            },
        ),
    );

    $c->response->body("");

    $c->detach;

    return;
}

sub add_breadcrumb {
    my ( $self, $c, @crumbs ) = @_;

    if ( ! exists $c->stash->{breadcrumbs} ) {
        $c->stash->{breadcrumbs} = [];
    }

    push @{ $c->stash->{breadcrumbs} }, @crumbs;

    return;
}

sub invalidate_form {
    # 2 args
    # $c, $errors ArrayRef of [$name, $message] ArrayRefs
    # 3 args
    # $c, $name, $message
    my $self   = shift @_;
    my $c      = shift @_;
    my $errors = shift @_;

    if (  @_ ) {
        $errors = [
            [ $errors, shift @_ ]
        ];
    }

    my $form = $c->stash->{form};

    for my $error ( @$errors ) {
        my ( $name, $message ) = @$error;

        $form->get_field({ nested_name => $name })->constraint({
            type         => 'Callback',
            callback     => sub{ die },
            message      => $message,
        });
    }

    $form->process;

    $c->stash->{rest}
        = { errors => $form->jquery_validation_errors_join('<br/>')};

    $c->detach;
}

sub process_data_tables {
    my ( $self, $c, $override ) = @_;

    my $form = $c->stash->{form};

    my %params = (
        sEcho          => 0,
        iDisplayStart  => 0,
        iDisplayLength => 10,
        iSortingCols   => 1,
        iSortCol_0     => 0,
        sSortDir_0     => 'asc',
        colNames       => ['id'],
        %$override,
    );

    if ( $form->submitted_and_valid ) {
        %params = (
            %params,
            %{ $form->params },
        );
    }

    my $col_name = $params{colNames}[ $params{iSortCol_0} ]
                || $params{colNames}[0];

    my %attrs = (
        order_by => { "-$params{sSortDir_0}" => $col_name },
        rows     => $params{iDisplayLength},
        page     => ( 1 + ( $params{iDisplayStart} / $params{iDisplayLength} ) ),
    );

    return (
        attrs => \%attrs,
        params => \%params,
    );
}

sub data_tables_response {
    my ( $self, $c, $dataTablesParams, $rs, $rows ) = @_;

    my %data = (
        sEcho  => $dataTablesParams->{params}{sEcho},
        aaData => $rows,
    );

    if ( $dataTablesParams->{attrs}{rows} ) {
        # count of all rows in this table - ignoring any filters
        $data{iTotalRecords} = $rs->result_source->resultset->count;

        # count of rows for this query - after any filters
        $data{iTotalDisplayRecords} = $rs->pager->total_entries;
    }

    return \%data;
}

1;
