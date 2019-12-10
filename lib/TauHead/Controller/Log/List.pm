package TauHead::Controller::Log::List;
use Moose;
use Try::Tiny;
use namespace::autoclean;

use TauHead::Util qw( html2text );

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);

    $c->assert_user_roles('admin');
}

sub list : Path('') : Args(0) : FormConfig {
    my ( $self, $c ) = @_;

    my $form = $c->stash->{form};
    my %dataTablesParams = $self->process_data_tables(
        $c,
        {
            colNames => [
                'me.datetime',
                'me.action',
                'user_account.username',
            ],
        },
    );

    my %params = (
        ip_address  => sub { sprintf "IP Address: %s", html2text( $_[0] ) },
        user_account_id     => sub { sprintf "user #%d", html2text( $_[0] ) },
        guid        => sub { sprintf "GUID: %s", html2text( $_[0] ) },
        owner_id    => sub { sprintf "association with user #%d", html2text( $_[0] ) },
    );

    $c->stash->{known_params} = [ keys %params ];

    my %cond;
    for my $param ( keys %params ) {
        if ( my $query = scalar $c->request->param( $param ) ) {
            $cond{$param} = $query;
            try {
                $c->stash->{legend} = $params{$param}->( $query );
            };
            last;
        }
    }

    return unless $c->request->accepts('application/json');

    my $rs = $c->model('DB')->resultset('Log')->search(
        \%cond,
        {
            join => [ 'user_account' ],
            '+select' => [ 'user_account.username' ],
            '+as'     => [ 'username' ],
            %{ $dataTablesParams{attrs} },
        },
    );
    my @rows;

    while ( my $log = $rs->next ) {
        # column 1 - datetime
        my @cols = ( $log->datetime->strftime("%F %R"), );

        # column 2 - title / link
        push @cols, sprintf q{<a href="%s" class="list-title">%s</a>},
            $c->uri_for( '/log', $log->id )->as_string,
            html2text( $log->action );

        # responder - column 3 - username
        if ( $log->user_account_id ) {
            push @cols, html2text( $log->get_column('username') );
        }
        else {
            push @cols, '';
        }

        push @rows, \@cols;
    }

    $c->stash->{rest} = $self->data_tables_response(
        $c,
        \%dataTablesParams,
        $rs,
        \@rows,
    );

    return;
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
