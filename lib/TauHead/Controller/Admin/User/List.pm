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
            ],
        },
    );

    my $model = $c->model('DB');

    my $rs = $model->resultset('UserAccount')->search(
        {},
        {
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

        # column 2 - status
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
