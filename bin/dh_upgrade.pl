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

my $schema_version = $dh->schema_version;
my $db_version     = $dh->database_version;

if ( $schema_version == $db_version ) {
	die "database is already at schema version '$schema_version'\n";
}

warn "Going to upgrade database currently at version '$db_version'\n";
warn "to schema version '$schema_version'\n";

$dh->prepare_deploy;
$dh->prepare_upgrade;
$dh->upgrade;
