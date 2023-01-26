#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '1.001';

use lib 'lib';

use Module::ScanDeps::Static;

__PACKAGE__->main();

sub main {

  exit Module::ScanDeps::Static->main;
} ## end sub main

1;
