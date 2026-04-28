# Module::ScanDeps::Static 1.8.0 Release Notes

## Overview

This release migrates the project from a legacy build system to
`CPAN::Maker::Bootstrapper`, bringing the full bootstrapper build
infrastructure - quality gates, dependency scanning, `cpanfile`
generation, and standardized make targets - to the distribution. No
functional changes to the module itself.

## Build System Migration

**Migrated to `CPAN::Maker::Bootstrapper`.** The project now uses the
bootstrapper build system with the standard `.includes/` make
infrastructure:

- `perl.mk` - syntax checking, perltidy, perlcritic quality gates with sentinel files
- `git.mk` - `make git` for repository initialization with recommended artifact staging
- `help.mk` - `make help` with target and variable documentation
- `release-notes.mk`, `update.mk`, `upgrade.mk`, `version.mk` - release workflow targets

**`buildspec.yml` added.** The distribution is now built via
`make-cpan-dist.pl` using a declarative YAML manifest. Resources,
dependencies, and paths are all declared in one place.

**`cpanfile` added.** Generated from `requires` and `test-requires`
for `cpanm --installdeps .` compatibility.

**Source files renamed to `.pm.in`.** `Module::ScanDeps::Static.pm`
and `Module::ScanDeps::FindRequires.pm` are now `.pm.in` sources. The
build generates the final `.pm` files with `@PACKAGE_VERSION@`
substitution, eliminating the need for the separate
`Module::ScanDeps::Static::VERSION` module.

**`Module::ScanDeps::Static::VERSION` removed.** Version is now
managed exclusively via the `VERSION` file and `@PACKAGE_VERSION@`
token substitution.

**`postamble` removed.** The modulino wrapper installation postamble
has been replaced by the bootstrapper's `make modulino` target
convention.

**`provides` file removed.** Managed by `buildspec.yml`.

## Changes

**`requires` updated with pinned versions.** All runtime dependencies
now specify minimum versions - `CLI::Simple 2.0.0`,
`Class::Accessor::Fast 0.51`, `JSON 4.10`, etc. `Pod::Find`.

**`test-requires` cleared.** `Test::More` is a Perl core module and
does not need to be listed explicitly.

**`help|h` option added to `FindRequires`.** The `--help` flag was
missing from the option specs.

**POD updated.** Script references updated from `find-requires.pl` to
`find-requires` throughout. Windows note added for
`find-requires.ps1`.

**Windows wrapper `find-requires.ps1` added.** A PowerShell wrapper
for running `Module::ScanDeps::FindRequires` on Windows.

**STDIN open fixed.** `open my $fh, '<&STDIN'` replaced with `open my
$fh, '<', \*STDIN` - the three-argument form is more portable and
avoids a perlcritic warning.

**`.gitignore` updated.** Now includes bootstrapper artifacts -
`.tdy`, `.crit`, generated `.pm`/`.pl`/`.sh` files, review artifacts,
and build outputs.
