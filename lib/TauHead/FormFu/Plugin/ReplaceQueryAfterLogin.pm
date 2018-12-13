package TauHead::FormFu::Plugin::ReplaceQueryAfterLogin;
use Moose;
use HTML::FormFu::FakeQuery;
use Storable qw( thaw );
extends 'HTML::FormFu::Plugin';

sub pre_process {
    my ($self) = @_;

    my $form = $self->form;
    my $c    = $form->stash->{context};
    my $guid = scalar $c->req->param('restore');

    return if !defined $guid;
    return if $guid !~ /^[a-zA-Z0-9-]{22}\z/;

    my $key = "restore_$guid";

    return if !exists $c->session->{$key};

    my $restore = delete $c->session->{$key};

    return if !defined $restore;

    my $params;

    eval {
        $params = thaw( $restore );
    };
    return if $@;

    $form->query(
        HTML::FormFu::FakeQuery->new( $form, $params )
    );
}

__PACKAGE__->meta->make_immutable;

1;
