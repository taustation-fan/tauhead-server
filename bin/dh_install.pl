#!/usr/bin/env perl
use strict;
use warnings;
use DBIx::Class::DeploymentHandler;
use Getopt::Long;
use YAML qw(LoadFile);
use FindBin;
use lib "$FindBin::RealBin/../lib";
use TauHead::Schema;

my $force_overwrite = 0;

GetOptions(
	'force_overwrite!' => \$force_overwrite,
) or die "Invalid options";

my $yaml = LoadFile("$FindBin::RealBin/../tauhead.yml");

my $schema = TauHead::Schema->connect(
	@{ $yaml->{'Model::DB'}{connect_info} }
);

my $dh = DBIx::Class::DeploymentHandler->new({
	schema              => $schema,
	script_directory    => "$FindBin::RealBin/../dbicdh",
	databases           => 'PostgreSQL',
	sql_translator_args => { add_drop_table => 0 },
	force_overwrite     => $force_overwrite,
});

$dh->prepare_install;
$dh->install;
