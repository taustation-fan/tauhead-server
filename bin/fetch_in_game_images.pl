#!/usr/bin/env perl
use strict;
use warnings;
use DBIx::Class;
use File::Path qw(make_path);
use LWP::UserAgent;
use LWP::Protocol::https;
use YAML qw(LoadFile);
use FindBin;
use lib "$FindBin::RealBin/../lib";
use TauHead::Schema;

my $yaml = LoadFile("$FindBin::RealBin/../tauhead.yml");

my $schema = TauHead::Schema->connect(
	@{ $yaml->{'Model::DB'}{connect_info} }
);

my $game_domain = $yaml->{game_server_domain};

my $ua = LWP::UserAgent->new;

my @paths;

{
    push @paths, $schema->resultset('Item')->search(
        undef,
        {
            'select' => [
                { 'distinct' => 'image', -as => 'imagex' },
            ],
            'as' => [
                'imagex',
            ]
        },
    )->get_column('imagex')->all;
}

for my $col (qw( bg_img content_img content_side_img hero_img other_img )) {
    my $as = "${col}x";

    push @paths, $schema->resultset('Area')->search(
        undef,
        {
            'select' => [
                { 'distinct' => $col, -as => $as },
            ],
            'as' => [
                $as,
            ]
        },
    )->get_column($as)->all;
}

@paths = sort { $a cmp $b }
    grep { defined && length }
    @paths;

for my $path (@paths) {

    if ( $path !~ m|^/static/images/| ) {
        warn "Filename doesn't start with /static/images/ - ignoring: '$path'\n";
        next;
    }

    my $local = "$FindBin::RealBin/../root$path";

    if ( -e $local ) {
        # warn "File already exists - skipping: '$local'\n";
        next;
    }

    my $dir = $local;
    $dir =~ s|[^/]+$||;

    if ( ! -d $dir ) {
        warn "Directory does not exists - will create: '$dir'\n";
        make_path $dir
            or do {
                warn "Failed to create directory: '$dir'\n";
                next;
            };
    }

    my $url = "$game_domain$path";

    my $response = $ua->get($url);
    if ( ! $response->is_success ) {
        warn "Failed to download: '$url'\n";
        warn "\t" . $response->message . "\n";
        last;
    }

    open my $fh, '>', $local
        or do {
            warn "Failed to open local file for writing: '$!': '$local'\n";
            next;
        };

    print $fh $response->content;
    close $fh;
    warn "Saved $local\n";
    sleep 1.5;
}
