#!/usr/bin/env perl
use strict;
use warnings;
use DBIx::Class;
use Digest;
use YAML qw(LoadFile);
use FindBin;

print "Enter password:\n";
chomp( my $password = <STDIN> );

my $yaml = LoadFile("$FindBin::RealBin/../tauhead.yml");

my $config = $yaml->{'Plugin::Authentication'}{default}{credential};

my $hash_type = $config->{password_hash_type};
my $pre_salt  = $config->{password_pre_salt};
my $post_salt = $config->{password_post_salt};

my $digest = Digest->new($hash_type);
$digest->add($pre_salt);
$digest->add($password);
$digest->add($post_salt);

my $b64 = $digest->clone->b64digest;

print "$b64\n";
