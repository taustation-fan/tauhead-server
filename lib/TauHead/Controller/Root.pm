package TauHead::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config( namespace => '' );

=encoding utf-8

=head1 NAME

TauHead::Controller::Root - Root Controller for TauHead

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) :Form {
    my ( $self, $c ) = @_;

    my $model = $c->model('DB');

    $c->stash->{systems} = $model->resultset('System')->search(
        undef,
        {
            order_by => ['sort_order', 'slug'],
        },
    );

    my $listing_rs = $model->resultset('AuctionListing');

    my $subquery = $listing_rs->search(
        undef,
        {
            '+select' => [
                { '' => \"max(me.last_seen_datetime) - interval '90 seconds'" },
            ],
            '+as' => [
                'cutoff_datetime'
            ]
        }
    );

    $c->stash->{latest_auctions} = $listing_rs->search(
        {
            last_seen_datetime => {
                '>=' => $subquery->get_column('cutoff_datetime')->as_query,
            },
        },
        {
            prefetch => ['item'],
            order_by => [ \'(me.price/me.quantity)', { -desc => 'me.last_seen_datetime' } ],
        }
    );

    my $form1 = $self->form->clone;
    $form1->load_config_filestem('stations_by_area/stations_by_area');
    $form1->process;
    $c->stash->{stations_by_area_form} = $form1;

    my $form2 = $self->form->clone;
    $form2->load_config_filestem('route_planner/route_planner');
    $form2->process;
    $c->stash->{route_planner_form} = $form2;

    return;
}

sub auto : Private {
    my ( $self, $c ) = @_;

    $c->load_status_msgs;

    return 1;
}

=head2 default

Standard 404 error page

=cut

sub default : Path {
    my ( $self, $c ) = @_;
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') { }

=head1 AUTHOR

Catalyst developer

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
