package TauHead::FormFu::Plugin::PathID;
use Moose;
extends 'HTML::FormFu::Plugin';

sub pre_process {
    my ($self) = @_;

    my $form = $self->form;
    my $req  = $form->stash->{context}->request;
    my $path = "formfu_" . $req->path;

    $path =~ s{[^a-zA-Z0-9]}{_}ga;

    $form->id( $path );
}

__PACKAGE__->meta->make_immutable;

1;
