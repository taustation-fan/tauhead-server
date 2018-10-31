package TauHead::Controller::API::Form;
use Moose;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub index : Path('/api/form') : Args(0) : FormConfig {}

__PACKAGE__->meta->make_immutable;

1;
