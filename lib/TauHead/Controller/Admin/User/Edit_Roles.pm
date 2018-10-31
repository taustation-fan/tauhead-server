package TauHead::Controller::Admin::User::Edit_Roles;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub edit_roles : PathPart('edit-roles') : Chained('../user') : Args(0) : FormConfig {}

sub edit_roles_FORM_NOT_SUBMITTED {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{view_user};
    my $form = $c->stash->{form};

    $form->model->default_values( $user );

    $form->process;
}

sub edit_roles_FORM_NOT_VALID {
    my ( $self, $c ) = @_;

    $c->stash->{rest}
        = { errors => $c->stash->{form}->jquery_validation_errors_join('<br/>'),
        };
}

sub edit_roles_FORM_VALID {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{view_user};
    my $form = $c->stash->{form};
    my ( @old_role_names, @old_role_ids,
         @new_role_names, @new_role_ids );

    for my $role ( $user->roles ) {
        push @old_role_names, $role->name;
        push @old_role_ids,   $role->id;
    }

    $form->model->update( $user );

    for my $role ( $user->roles ) {
        push @new_role_names, $role->name;
        push @new_role_ids,   $role->id;
    }

    my $msg      = "User roles updated.";
    my $redirect = $c->uri_for( "/admin/user", $user->id, { mid => $c->set_status_msg($msg) } );

    $c->stash->{rest} = {
        ok       => 1,
        redirect => $redirect->as_string,
    };

    $self->add_log( $c, 'admin/user/edit-roles',
        {
            description => "Changed user roles",
            owner_id    => $user->id,
            old_roles   => join( ', ', sort { $a cmp $b } @old_role_names),
            new_roles   => join( ', ', sort { $a cmp $b } @new_role_names),
        },
    );

    $c->detach;
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
