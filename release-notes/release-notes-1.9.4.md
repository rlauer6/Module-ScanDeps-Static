# Module::ScanDeps::Static 1.9.4 Release Notes

## Overview

This release adds optional logging support to the scanner, fixes
Perl version string handling, corrects a build dependency target, and
trims redundant runtime dependency declarations.

---

## Scanner Changes

### Perl Version String Handling (`parse_line`)

Two related fixes improve how Perl version requirements embedded in
source files are recognized and recorded:

- **v-string declarations are now preserved.** Previously, a
  declaration such as `use v5.24;` could have its leading `v`
  stripped before being stored. The version string is now captured
  intact.
- **Discovered Perl versions are normalized with
  `version->parse`.** After capture, any version string (with or
  without a leading `v`) is passed through `version->parse` and
  stored in numified form (e.g., `5.024000`). This makes version
  comparisons consistent regardless of how the version was written
  in the source.

### Logging Support (`logger`, `cmd_scan`, `_extra_options`,
`_option_specs`)

A new `logger` method has been added. It provides a uniform logging
interface that works whether or not `Log::Log4perl` is available:

- When a `Log::Log4perl` logger object is supplied via the `logger`
  extra option, log calls are delegated to it.
- When no logger is configured, the method falls back to printing
  `info` or `debug` messages to STDERR, gated by the value of
  `--log-level`.

The `--log-level` option previously accepted no argument; it now
correctly takes a string value (`--log-level=info`, `--log-level=debug`,
etc.).

`cmd_scan` uses the new `logger` method to emit an `info`-level
message for each file as it is scanned. This makes it straightforward
to follow progress when scanning a large `--file-list` batch, without
requiring a full `Log::Log4perl` configuration.

---

## Dependency Changes

Three modules have been removed from the runtime requirements in
`cpanfile` and `requires`:

- `CLI::Simple::Constants`
- `CLI::Simple::Utils`
- `Progress::Any::Output`

These were redundant: `CLI::Simple::Constants` and
`CLI::Simple::Utils` are part of the `CLI::Simple` distribution
already declared as a dependency, and `Progress::Any::Output` is a
namespace rather than an installable module in its own right.

---

## Build System Changes

### `deps.mk` Fix

The generated dependency target for `bin/scandeps-static.pl` was
incorrect in the previous release. It has been corrected so that
`bin/scandeps-static.pl` properly depends on
`./lib/Module/ScanDeps/Static.pm`.

### Build Infrastructure Update

Several `.includes/` make fragments have been added or updated by
`CPAN::Maker::Bootstrapper`. New additions include:
`bash-completion.mk`, `bootstrap.mk`, `build-init.mk`, `builder.mk`,
`local.mk`, `modulino.mk`, `publish.mk`, and `test.mk`. Existing
fragments (`git.mk`, `help.mk`, `perl.mk`, `release-notes.mk`,
`update.mk`, `version.mk`) have also been refreshed. These changes
affect the development and release workflow but have no effect on the
installed module or its runtime behavior.

---

