#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'TauHead';
all_from 'lib/TauHead.pm';

requires 'Catalyst::Runtime' => '5.90051';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::Serialize';
requires 'Catalyst::Action::RenderView';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::Store::DBIC';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Plugin::SubRequest';
requires 'Catalyst::Authentication::Store::DBIx::Class';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Plugin::Scheduler';
requires 'Catalyst::Plugin::StatusMessage';
requires 'Catalyst::TraitFor::Request::REST';
requires 'Catalyst::View::TT';
requires 'CatalystX::RoleApplicator';
requires 'Cpanel::JSON::XS';
requires 'DateTime::Format::Duration';
requires 'DateTime::Format::TauStation';
requires 'DBD::MariaDB';
requires 'DBIx::Class::DeploymentHandler';
requires 'DBIx::Class::InflateColumn::Serializer';
requires 'FCGI';
requires 'HTML::FormFu';
#requires 'HTML::FormFu::Constraint::DBIC::Exists'; # not currently in the HTML-FormFu-Model-DBIC dist
requires 'HTML::FormFu::Constraint::DBIC::Unique';
requires 'HTML::FormFu::Role::JQueryValidation';
requires 'Catalyst::Controller::HTML::FormFu';
requires 'HTML::FormFu::Model::DBIC';
requires 'HTML::FormFu::TauStation';
requires 'DBIx::Class::DeploymentHandler';
requires 'DBIx::Class::InflateColumn::DateTime';
requires 'DBIx::Class::InflateColumn::Serializer';
requires 'DBIx::Class::ResultClass::HashRefInflator';
requires 'Data::GUID::URLSafe';
requires 'DateTime::Format::MySQL';
requires 'HTML::Escape';
requires 'MIME::Lite';
requires 'POSIX';
requires 'Proc::ProcessTable';
requires 'Scalar::Util';
requires 'Storable';
requires 'Template::Plugin::HtmlToText';
requires 'Try::Tiny';
requires 'URI::Find::Schemeless';
requires 'YAML::XS';

test_requires 'Test::More' => '0.88';
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
