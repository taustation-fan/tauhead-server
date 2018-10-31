package TauHead::Controller::GCT;
use Moose;
use Cpanel::JSON::XS qw( encode_json );
use DateTime::Format::Duration;
use DateTime::Format::TauStation;
use namespace::autoclean;

BEGIN { extends 'TauHead::BaseController' }

sub gct : Chained('/') : Args(0) : FormConfig { }

sub gct_FORM_NOT_SUBMITTED {
    my ( $self, $c ) = @_;

    my $form = $c->stash->{form};

    $form->get_field('datetime')->default(
        DateTime::Format::TauStation->format_datetime(
            DateTime::Calendar::TauStation->now
        )
    );
}

sub gct_FORM_NOT_VALID {
    my ( $self, $c ) = @_;

    $c->stash->{rest}
        = { errors => $c->stash->{form}->jquery_validation_errors_join('<br/>'),
        };
}

sub gct_FORM_VALID {
    my ( $self, $c ) = @_;

    my $form   = $c->stash->{form};
    my $params = $form->params;

    if ( my $dt = $params->{datetime} ) {
        my $now = DateTime::Calendar::TauStation->now;
        my $dur = $dt->subtract_datetime( $now );

        my $format = DateTime::Format::Duration->new(
            pattern   => "%Y years, %m months, %e days, %H hours, %M minutes, %S seconds",
            normalize => 1,
        );

        $c->stash->{datetime_oe}  = $dt->stringify;
        $c->stash->{duration_neg} = ( $dt->epoch < $now->epoch );
        $c->stash->{duration_oe}  = DateTime::Format::TauStation->format_duration($dur);
        $c->stash->{duration_gtc} = $format->format_duration( $dur );
    }
}

sub end : ActionClass('RenderView') { }

__PACKAGE__->meta->make_immutable;

1;
