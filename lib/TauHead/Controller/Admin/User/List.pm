package TauHead::Controller::Admin::User::List;
use Moose;
use DateTime::Format::MySQL;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub list : PathPart('user/list') : Chained('../../admin') : Args(0) : FormConfig {
    my ( $self, $c ) = @_;

    if ( $c->request->accepts('application/json') ) {
        $self->_list_json( $c );
    }
}

sub _list_json {
    my ( $self, $c ) = @_;

    my $form = $c->stash->{form};

    my %dataTablesParams = $self->process_data_tables(
        $c,
        {
            colNames => [
                'me.username',
                'last_login',
            ],
        },
    );

    my $model = $c->model('DB');

    my $last_login_rs = $model->resultset('Log')->search(
        {
            user_account_id => { -ident => 'outer_id' },
        },
        {
            columns  => [ 'datetime' ],
            order_by => { -desc => 'datetime' },
            rows     => 1,
        },
    )->as_query;

    my $rs = $model->resultset('UserAccount')->search(
        {},
        {
            '+select' => [
                { '' => 'me.id', -as => 'outer_id' },
                { '' => $last_login_rs, -as => 'last_login' },
            ],
            '+as' => [
                'outer_id',
                'last_login',
            ],
            %{ $dataTablesParams{attrs} },
        },
    );

    my @users;
    while ( my $user = $rs->next ) {
        my @row;

        # column 1 - username
        push @row, sprintf q{<a href="%s" class="username">%s</a>},
            $c->uri_for( '/admin/user', $user->id ),
            $user->username;

        # column 2 - last login
        if ( my $last_login = $user->get_column('last_login') ) {
            # last_login isn't inflated, so parse it properly
            my $dt = DateTime::Format::MySQL->parse_datetime( $last_login );
            push @row, $dt->strftime('%F');
        }
        else {
            push @row, 'Never';
        }

        # column 3 - status
        if ( $user->disabled ) {
            push @row, "<b>Disabled<b>";
        }
        elsif ( ! $user->email_confirmed ) {
            push @row, "<b>Awaiting email confirmation</b>";
        }
        else {
            push @row, "OK";
        }

        push @users, \@row;
    }

    $c->stash->{rest} = $self->data_tables_response(
        $c,
        \%dataTablesParams,
        $rs,
        \@users,
    );

    return;
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
