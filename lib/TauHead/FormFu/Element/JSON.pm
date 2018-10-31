package TauHead::FormFu::Element::JSON;
use Moose;
use Cpanel::JSON::XS ();

extends 'HTML::FormFu::Element::Textarea';

after BUILD => sub {
    my $self = shift;

    $self->rows(3);

    $self->constraints( [
        { type => 'SingleValue' },
        { type => 'JSON' },
    ] );

    $self->filters([
        {
            type    => 'Regex',
            match   => qr/^\s*null\s*$/,
            replace => '',
        },
        {
            type => 'Callback',
            callback => sub {
                # ensure encoded string is always sorted by keys
                my ( $value ) = @_;
                return $value if !defined $value;
                return $value if !length $value;
                return $value if 'null' eq $value;

                my $json = Cpanel::JSON::XS->new;
                $json->canonical(1);
                my $decoded = $json->decode($value);
                
                return $json->encode($decoded);
            },
        }
    ]);

    return;
};

__PACKAGE__->meta->make_immutable;

1;
