# Module::ScanDeps::Static 1.8.1 Release Notes

**Released:** Sun Jul 19 2026  
**Author:** Rob Lauer <rclauer@gmail.com>

---

## Overview

This is a maintenance release focused on bug fixes in
`Module::ScanDeps::Static`, expanded role composition support,
significantly improved POD documentation, and build tooling updates
via `CPAN::Maker::Bootstrapper`.

---

## What's New

### `Module::ScanDeps::Static` — New Feature

#### Role Composition Support (`parse_line`)

`parse_line` now recognises Moo/`Role::Tiny::With`-style `with`
statements and correctly registers their role arguments as
dependencies. All common syntax variants are handled:

```perl
with 'Foo';
with 'Foo', 'Bar';
with qw(Foo Bar);
with('Foo');
with('Foo', 'Bar');
```

The parser anchors on `with` as the leading token to avoid false
matches on `without`, hash keys (`with => ...`), or prose in comments
and POD.

---

## Bug Fixes

### `to_rpm` — Corrected Perl Version Iteration

`to_rpm` was incorrectly iterating over the **keys** of the `perlreq`
hash instead of the **values** when building the `perl >= version`
requirement line. This has been fixed:

```perl
# Before (incorrect)
foreach my $perlver ( sort keys %{ $self->get_perlreq } ) { ... }

# After (correct)
foreach my $perlver ( sort values %{ $self->get_perlreq } ) { ... }
```

### `to_rpm` — Corrected `sprintf`-style String Interpolation

A `push` statement was using a `sprintf` format string with a `%s`
placeholder but was not calling `sprintf`. The version string is now
interpolated directly:

```perl
# Before (broken)
push @rpm_deps, "perl($module) >= %s", $m->{'version'};

# After (correct)
push @rpm_deps, "perl($module) >= $m->{'version'}";
```

### `to_rpm` — Return Value Now Newline-Terminated

`to_rpm` now returns a properly newline-terminated string by appending
an empty string to the final `join`:

```perl
return join $NEWLINE, @rpm_deps, $EMPTY;
```

### `new` — `text` Option Defaults to `true`

The `text` option in the constructor was not being defaulted, which
could lead to unexpected output formatting. It now defaults to
`$TRUE`:

```perl
$options{text} //= $TRUE;
```

### `check_syntax_pl` — Incorrect `perl -wc` Invocation

The syntax check for `.pl` files was incorrectly passing
`-M"$$module"` (a module flag) when checking plain scripts. This has
been removed; scripts are now checked with `perl -wc` alone.

---

## POD / Documentation Improvements

Extensive documentation updates were made to `Module::ScanDeps::Static`:

- **Constructor options** (`path`, `handle`, `include_require`,
  `add_version`, `core`, `min_core_version`, `json`, `text`, `raw`,
  `separator`) now have accurate descriptions, correct defaults, and
  clarified interactions with the CLI.
- **New method documentation** added for:
  - `get_perlreq` — describes the returned hash ref and its structure.
  - `format_text` — documents options honoured and output format.
  - `format_json` — documents scalar vs. list context behaviour.
  - `is_core` — documents version-based core module detection logic.
  - `min_core_version` — clarifies distinction from the generated accessor.
  - `get_module_version` — documents return structure and lookup behaviour.
  - `add_require` — documents version retention and return value.
  - `to_rpm` — documents output format and core-filtering behaviour.
- **Typo fixes:** `dafault` → `default`, `verion` → `version`.
- **CLI reference fix:** `find-requires.pl` → `find-requires`.
- **`--include-require` default** clarified in option description.
- **`--min-core-version` default** now correctly documented as the
  running Perl's version (constructor) vs. `5.8.9` (CLI).
- **JSON example** corrected: missing `:` separator added.
- **Context-sensitivity note** added to `get_dependencies`.
- Trailing whitespace removed from `parse from file handle` example.

---

## Build System Changes

All build include files were updated by `CPAN::Maker::Bootstrapper`.

### `Makefile`

- Added `BOOTSTRAPPER_VERSION` detection.
- Replaced `make-cpan-dist.pl` invocations with `cpan-maker` commands;
  `cpanfile` generation now uses `cpan-maker create-cpanfile`.
- `SCAN` is now automatically set to `OFF` when `scandeps-static.pl` is not found.
- `BOOTSTRAPPER` absence is now a hard `$(error ...)`.
- `find-files` macro is now robust against missing directories.
- `scan-deps` macro reads `min-perl-version` from `buildspec.yml` and passes it to `scandeps-static.pl` via `-m`.
- Added `update-available` to the default dependency list.
- Added new targets: `workflow`, `build-ci`, `test`, `check`.
- Added `clean-local` extensible phony target.
- `module.pm.tmpl`, `test.t.tmpl`, and `buildspec.yml.tmpl` targets now handle missing templates gracefully with `|| true`.
- `buildspec.yml` target now sets `chmod 0644` on the output file.
- `README.md` generation now gracefully warns and skips if `Markdown::Render` or `Pod::Markdown` are not installed.
- `$(MODULE_PATH).in` now depends on (rather than ordering after) `module.pm.tmpl`, and removes the template after use.
- `diff` command in tidy check had a redundant `2>/dev/null 2>&1`; corrected to `2>/dev/null`.
- `GIT_NAME`, `GIT_EMAIL`, `GITHUB_USER` now suppress stderr from `git config`.
- `CLEANFILES` now includes `cmb_md5sums.txt`.

### `.includes/perl.mk`

- Replaced `PODEXTRACT` detection with `PODCHECKER` (`podchecker`).
- `tidy_on` and `critic_on` are now only defined when
  `perltidy`/`perlcritic` are actually present on `PATH`.
- `check_syntax_pm` and `check_syntax_pl` now run `podchecker` after
  the syntax check; POD errors fail the build.
- Temporary file cleanup switched from `trap`-based `EXIT` handlers to
  `local_cleanfiles` accumulation.

### `.includes/update.mk`

- `BOOTSTRAPPER_DIST_DIR` now suppresses errors with `|| true`.
- `post-update` sets files read-only after copying (`chmod -w`).
- `update` target now conditionally updates `builder` if present, and
  sets `Makefile` and `.includes/*` read-only after update.
- New `update-available` target checks CPAN for a newer
  `CPAN::Maker::Bootstrapper` and validates local file integrity
  against installed md5sums, with configurable `CMB_UPDATE_CHECK` and
  `CMB_VERSION_DRIFT` settings.

### `.includes/git.mk`

- `git` target now supports `NO_COMMIT=1` to stage without committing.
- `git init` output suppressed.
- All shell commands chained correctly within a single recipe.

### `.includes/release-notes.mk`

- Release notes generation now delegates to `bootstrapper
  release-notes` instead of inline shell script logic.

### `buildspec.yml`

- Keys normalised from underscore to hyphen convention (`pm_module` →
  `pm-module`, `test_requires` → `test-requires`, `pm_module` path →
  `pm-module`, `exe_files` → `exe-files`).

### `cpanfile` / `requires`

- Removed `version 0.9930` dependency.
- `Progress::Any::Output::TermProgressBarColor` entry sorted alphabetically.

### `.gitignore`

- Added `buildspec.yml.current` to ignored files.

---

## Dependency Changes

| Package | Change |
|---|---|
| `version` | **Removed** from `requires` and `cpanfile` |

All other runtime dependencies remain unchanged.
