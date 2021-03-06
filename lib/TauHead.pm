package TauHead;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    ConfigLoader
    Authentication
    Authorization::Roles
    Session
    Session::Store::DBIC
    Session::State::Cookie
    Scheduler
    StatusMessage
    SubRequest
    /;

use CatalystX::RoleApplicator;

extends 'Catalyst';

our $VERSION = '0.01';

__PACKAGE__->apply_request_class_roles( qw[
        Catalyst::TraitFor::Request::REST
] );

# Configure the application.
#
# Note that settings in tauhead.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'TauHead',

    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
);

# Start the application
__PACKAGE__->setup();

sub system_email_address {
    my ( $self ) = @_;

    return $self->config->{system_email_address};
}

sub login_attempts_limit {
    my ( $self ) = @_;

    return $self->config->{login_attempts_limit};
}

=encoding utf8

=head1 NAME

TauHead - Catalyst based application

=head1 SYNOPSIS

    script/tauhead_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<TauHead::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Catalyst developer

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
