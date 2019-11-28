package TauHead::Controller::Signup;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub index : Path('') : Args(0) { }

sub end : ActionClass('Serialize') { }

__PACKAGE__->meta->make_immutable;

1;
