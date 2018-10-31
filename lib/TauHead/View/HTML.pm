package TauHead::View::HTML;
use Moose;
use namespace::autoclean;

use TauHead::Util ();
use Template::Plugin::HtmlToText;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die         => 1,
    FILTERS => {
        linkify => \&TauHead::Util::linkify,
        camel2words => \&TauHead::Util::camel2words,
        json2txt => \&TauHead::Util::json2txt,
    },
);

sub sort_by_datetime {
    my ( $self, $c, @args ) = @_;

    return sort { $a->datetime cmp $b->datetime } @args;
}

=head1 NAME

TauHead::View::HTML - TT View for TauHead

=head1 DESCRIPTION

TT View for TauHead.

=head1 SEE ALSO

L<TauHead>

=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
