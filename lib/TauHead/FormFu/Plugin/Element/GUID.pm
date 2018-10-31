package TauHead::FormFu::Plugin::Element::GUID;
use Moose;
use Data::GUID::URLSafe;
extends 'HTML::FormFu::Plugin';

sub post_process {
    my ($self) = @_;

    return if $self->form->submitted;
    
    my $element = $self->parent;
    
    return if $element->default;
    
    my $guid = Data::GUID->new->as_base64_urlsafe;
    
    $element->default( $guid );
}

__PACKAGE__->meta->make_immutable;

1;
