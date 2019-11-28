use utf8;

package TauHead::Schema::Result::User;

use strict;
use warnings;
use List::Util qw( any );

use base 'DBIx::Class::Core';

__PACKAGE__->table("user");

__PACKAGE__->add_columns(
    "id",
    {   data_type         => "integer",
        extra             => { unsigned => 1 },
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "username",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "password_base64",
    { data_type => "varchar", is_nullable => 0, size => 255 },
    "password_type",
    { data_type => "varchar", is_nullable => 0, size => 255 },
    "email",
    { data_type => "varchar", is_nullable => 0, size => 128 },
    "email_confirmed",
    { data_type => "boolean", default_value => 0, is_nullable => 0 },
    "disabled",
    { data_type => "boolean", default_value => 0, is_nullable => 0 },
    "disabled_reason",
    { data_type => "mediumtext", is_nullable => 0, default_value => "" },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint( "email", ["email"] );

__PACKAGE__->add_unique_constraint( "username", ["username"] );

__PACKAGE__->might_have(
    "email_change_request",
    "TauHead::Schema::Result::EmailChangeRequest",
    { "foreign.user_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->might_have(
    "verify_email_request",
    "TauHead::Schema::Result::VerifyEmailRequest",
    { "foreign.user_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->might_have(
    "password_change_request",
    "TauHead::Schema::Result::PasswordChangeRequest",
    { "foreign.user_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->might_have(
    "unlock_account_request",
    "TauHead::Schema::Result::UnlockAccountRequest",
    { "foreign.user_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
    "user_roles",
    "TauHead::Schema::Result::UserRole",
    { "foreign.user_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many( "roles", "user_roles", "role", );

__PACKAGE__->has_many(
    "logs",
    "TauHead::Schema::Result::Log",
    { "foreign.user_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
    "login_failure",
    "TauHead::Schema::Result::LoginFailure",
    { "foreign.user_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
    "user_preferences",
    "TauHead::Schema::Result::UserPreference",
    { "foreign.user_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
    "auction_listing_records",
    "TauHead::Schema::Result::AuctionListingRecord",
    { "foreign.user_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many( "preferences", "user_preferences", "preference", );

__PACKAGE__->has_many(
    "data_gatherer",
    "TauHead::Schema::Result::DataGatherer",
    { "foreign.user_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

sub last_login {
    my ($self) = @_;

    return $self->search_related(
        'logs',
        {
            action => 'login',
        },
        {
            order_by => ['datetime DESC'],
            rows     => 1,
        },
    )->single;
}

sub has_role {
    my ( $self, $role ) = @_;

    die "has_role() doesn't take a role object"
        if ref $role;

    return any {
        $_->name eq $role
    } $self->roles;
}

sub all_users_with_preference {
    my ( $self, $pref_name, $pref_value ) = @_;

    return $self->search(
        {
            'me.email_confirmed'     => 1,
            'me.disabled'            => 0,
            'preference.name'        => $pref_name,
            'user_preferences.value' => $pref_value,
        },
        {
            join => {
                user_preferences => 'preference',
            },
        },
    );
}

sub apply_default_preferences {
    my ( $self ) = @_;

    my $schema = $self->result_source->schema;

    my @role_ids = sort map { $_->id } $self->roles;

    my @all_prefs = $schema->resultset('Preference')->search(
        {},
        {
            columns => ['id'],
        },
    )->get_column('id')->all;

    my @current_prefs = $self->search_related(
        'user_preferences',
        undef,
        {
            columns => ['preference_id'],
        },
    )->get_column('preference_id')->all;

    for my $pref_id (@all_prefs) {
        next if any { $_ == $pref_id } @current_prefs;

        my $default = $schema->resultset('Preference')->find( $pref_id )->default_value;

        $self->create_related(
            'user_preferences',
            {
                preference_id => $pref_id,
                value         => $default,
            },
        );
    }

    return;
}

1;
