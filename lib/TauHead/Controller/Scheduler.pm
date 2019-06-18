package TauHead::Controller::Scheduler;
use Moose;
use Cpanel::JSON::XS;
use HTML::FormFu;
use Scalar::Util qw( reftype );
use Try::Tiny;
use utf8;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub default : Path {
    my ( $self, $c ) = @_;

    $c->response->status(204);
    $c->response->content_length(0);
    $c->response->body("");
}

sub _validate_result_json {
    my ( $self, $result, $form ) =  @_;

    my $json;
    my $ok;
    $ok = try {
        $json = Cpanel::JSON::XS->new->decode( $result->json );
        1;
    };
    if ( ! $ok ) {
        $result->update({
            held             => 1,
            datetime_updated => \"NOW()",
            message          => "json decode failed",
        });
        return;
    }

    $ok = try {
        $form->process($json);
        1;
    }
    catch {
        $result->update({
            held             => 1,
            datetime_updated => \"NOW()",
            message          => "form process failed",
        });
        return undef;
    };
    return unless $ok;

    if ( !$form->submitted_and_valid ) {
        $result->update({
            held             => 1,
            datetime_updated => \'NOW()',
            message          => "form not valid",
        });
        return;
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
