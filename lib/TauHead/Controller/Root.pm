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

sub index :Path :Args(0) :FormConfig {
    my ( $self, $c ) = @_;

    my $model = $c->model('DB');

    $c->stash->{systems} = $model->resultset('System')->search(
        undef,
        {
            order_by => ['sort_order', 'slug'],
        },
    );

    return;
}

sub auto : Private {
    my ( $self, $c ) = @_;

    $c->load_status_msgs;

    return 1;
}

sub area_search :Path('area-search') : Chained('/') : Args(0) : FormConfig('index') {
}

sub area_search_FORM_VALID {
    my ( $self, $c ) = @_;

    my $form = $c->stash->{form};
    $c->stash->{query_with} = $form->param_value('with');
    $c->stash->{query_area} = $form->param_value('area');

    my $model = $c->model('DB');

    $c->stash->{systems} = $model->resultset('System')->search(
        undef,
        {
            order_by => ['sort_order', 'slug'],
        },
    );

    return;
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
