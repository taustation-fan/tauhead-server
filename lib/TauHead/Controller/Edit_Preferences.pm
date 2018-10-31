package TauHead::Controller::Edit_Preferences;
use Moose;
use MIME::Lite;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub auto : Private {
    my ( $self, $c ) = @_;

    $self->require_login($c);
}

sub edit_preferences : Path('/edit-preferences') : Args(0) : FormConfig {
}

sub edit_preferences_FORM_NOT_VALID {
    my ( $self, $c ) = @_;

    $c->stash->{rest}
        = { errors => $c->stash->{form}->jquery_validation_errors_join('<br/>'),
        };
}

sub edit_preferences_FORM_VALID {
    my ( $self, $c ) = @_;

    my $form    = $c->stash->{form};
    my $user_rs = $c->user->obj;

    my $prefs = $user_rs->user_preferences;

    while ( my $user_pref = $prefs->next ) {
        my $pref = $user_pref->preference;

        my $value = $form->valid( $pref->id ) ? $form->param_value( $pref->id )
                                              : $pref->default_value;

        next if $value eq $user_pref->value;

        my $old_value = $user_pref->value;

        $user_pref->update( {
            value => $value,
        } );

        $self->add_log( $c, 'edit-preferences', {
            description            => 'User updated own preferences',
            preference             => $pref->name,
            preference_label       => $pref->display_label,
            preference_description => $pref->description,
            old_value              => $old_value,
            new_value              => $value,
        } );
    }

    my $msg = "Preferences updated.";

    $c->stash->{rest} = {
        ok => 1,
        redirect => $c->uri_for(
            "/account",
            { mid => $c->set_status_msg($msg) },
        )->as_string,
    };
}

sub send_email_password_changed {
    my ( $self, $c, $user ) = @_;

    my $body = <<BODY;
Your TauHead password has been changed.
BODY

    my $msg = MIME::Lite->new(
        From    => $c->system_email_address,
        To      => $user->email,
        Subject => 'TauHead: Your password has been changed.',
        Data    => $body,
    );

    $msg->send;
}

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
