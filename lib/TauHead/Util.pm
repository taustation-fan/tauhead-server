package TauHead::Util;
use strict;
use warnings;
use Exporter qw( import );

use HTML::FormatText;
use HTML::TreeBuilder;
use Cpanel::JSON::XS qw( decode_json );
use URI::Find::Schemeless;

our @EXPORT_OK = qw( camel2words linkify html2text json2txt );

sub camel2words {
    my ($status) = @_;

    my @words = split /_/, $status;

    return
        join ' ',
        map { ucfirst $_; } @words;
}

sub linkify {
    my ($text) = @_;

    my $finder = URI::Find::Schemeless->new( sub {
        my ($uri, $orig_uri) = @_;

        return qq|<a href="$uri" target="_blank">$orig_uri</a>|;
    } );

    $finder->find(\$text);

    return $text;
}

sub json2txt {
    my ( $json ) = @_;

    eval {
        $json = decode_json( $json );
    };
    return $json if $@;

    return $json if 'HASH' ne ref $json;

    my $txt = "";
    for my $key ( sort { $a cmp $b } keys %$json ) {
        $txt .= sprintf "%s: %s\n", camel2words($key), $json->{$key};
    }

    return $txt;
}

# copied from Template::Plugin::HtmlToText

sub html2text {
    my ( $html ) = @_;

    return $html unless ($html =~ m#(<|>)#s);

    my $tree = HTML::TreeBuilder->new->parse($html);
    my $formatter = HTML::FormatText->new;
    my $text = $formatter->format($tree);

    return $text;
}

1;
