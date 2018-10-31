#!/usr/bin/env perl
use strict;
use warnings;
use DBIx::Class::DeploymentHandler;
use YAML qw(LoadFile);
use FindBin;
use lib "$FindBin::RealBin/../lib";
use TauHead::Schema;

my $yaml = LoadFile("$FindBin::RealBin/../tauhead.yml");

my $schema = TauHead::Schema->connect(
	@{ $yaml->{'Model::DB'}{connect_info} }
);

my $dh = DBIx::Class::DeploymentHandler->new({
	schema              => $schema,
	script_directory    => "$FindBin::RealBin/../dbicdh",
	databases           => 'MySQL',
	sql_translator_args => { add_drop_table => 0 },
});

printf "%d\n", $dh->database_version;
