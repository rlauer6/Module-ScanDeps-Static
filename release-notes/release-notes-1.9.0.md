# Release Notes — Module::ScanDeps::Static 1.9.0

**Released:** 2026-07-21  
**Distribution:** `Module-ScanDeps-Static`  
**Author:** Rob Lauer &lt;rclauer@gmail.com&gt;

---

## Overview

Version 1.9.0 introduces batch-file scanning, a correctness fix to core-module
detection, a build-system overhaul that eliminates a longstanding
chicken-and-egg dependency problem, and a handful of polish items throughout.

---

## New Features

### `--file-list` / `-L PATH` — Batch File Scanning

`scandeps-static.pl` can now scan an entire list of source files in a single
process invocation instead of one file per call.

```
scandeps-static.pl --file-list file_list.tmp --no-core
```

`PATH` is a plain text file containing one source-file path per line (relative
or absolute). All listed files are scanned in turn and their results are
aggregated.

**Why this matters:**  
Perl's own startup cost and, more significantly, the cost of loading
`Module::CoreList` (roughly an order of magnitude slower than a bare `perl`
startup) were previously paid once per file scanned. For projects with more
than a handful of source files the saving is substantial.

**`--json` interaction:**  
Because multiple JSON documents cannot be safely concatenated into a single
valid result, `--json` is silently ignored when `--file-list` resolves to more
than one file — output is always text in that case. When the list contains
exactly one file, `--json` is honoured normally.

The `Makefile` scan-deps logic has been updated to collect all files first and
call `scandeps-static.pl` once with `--file-list`, replacing the previous
per-file loop.

---

### `--path` / `-p PATH` — Named Path Option

The path to the file being scanned may now be supplied as a named option
(`--path myfile.pl`) in addition to the existing positional argument. Useful
when building command lines programmatically. Ignored if `--file-list` is also
given.

---

## Bug Fixes

### `is_core` — Removed-from-Core Modules Always Treated as Non-Core

Previously, a module that had been present in Perl core but was subsequently
**removed** could still be reported as core depending on how
`min_core_version` compared to the removal version. This was unsafe: there is
no way to know which specific Perl an end user has installed, so a module that
has ever been removed cannot be assumed to be available.

**New behaviour:** any module for which `Module::CoreList->removed_from()`
returns a value is unconditionally treated as non-core, regardless of
`min_core_version`. Only modules that have a recorded first release *and have
never been removed* can be considered core.

The `--min-core-version` option documentation has been updated to describe this
distinction explicitly.

---

### `is_core` — Removed Unnecessary `find_modules` Call

The previous implementation called `Module::CoreList->find_modules()` (a regex
scan over the entire core-module list) before calling
`first_release`/`removed_from`. This extra pass was not needed; `is_core` now
calls `first_release` and `removed_from` directly, improving performance.

---

## CLI Changes

- `bin/scandeps-static.pl` now uses an explicit `exit` on the return value of
  `main()` (`exit __PACKAGE__->main()`) so that the exit code is correctly
  propagated to the shell.
- `main()` default options hash keys have been sorted for readability.

---

## Dependency Changes

Two new runtime dependencies have been added to replace the previously inlined
boolean and character constants (which in turn removes the direct `Readonly`
usage from the main module body — `Readonly` is still a dependency but is no
longer used for per-constant declarations inline):

| Module | Minimum Version | Purpose |
|---|---|---|
| `CLI::Simple::Constants` | 2.1.1 | Boolean and character constants (`:booleans`, `:chars`) |
| `CLI::Simple::Utils` | 2.1.1 | Utility helpers (`slurp`) |

`cpanfile` and `requires` have been updated accordingly.

---

## Build System Changes

### `deps.mk` Now Depends on Source Files, Not Built Artifacts

`deps.mk` previously declared a dependency on the built `.pm` / `.pl` targets,
which caused `make clean` to rebuild every module (just to then delete it) and
created a chicken-and-egg problem under parallel builds.

`deps.mk` now depends on the `.pm.in` / `.pl.in` **source** files:

```makefile
deps.mk: $(SOURCE_FILES:%=%.in)
```

`cmb create-deps` already scans `.pm.in` directly, so:

- `deps.mk` regenerates purely from source edits — no build artifacts involved.
- `make clean` can never trigger a rebuild through the `deps.mk` include.
- The `-include deps.mk` guard that previously skipped the include for
  `clean`/`distclean` goals has been removed; the include is now unconditional.

### Templating and Syntax-Checking Re-Combined

The `%.pm` / `%.pl` pattern rules previously split templating and syntax
checking into separate sentinel files (`.pm.checked` etc.) to work around the
`deps.mk` chicken-and-egg problem. Now that the problem is resolved at source,
both steps are combined back into a single pattern rule. Correct dependency
ordering under `-j` is maintained by real Make graph edges rather than a
separate phase-barrier pass.

### `check-syntax` Target

A `.PHONY: check-syntax` convenience alias is retained (and is now an explicit
prerequisite of the `$(TARBALL)` target) so that existing workflows continue to
work unchanged. It simply depends on `$(PERL_MODULES)` and `$(PERL_BIN_FILES)`.

### `compile.skip` Support

The `check_syntax_pm` and `check_syntax_pl` make snippets now read a
`compile.skip` file (if present) in addition to the `$(PERLWC_SKIP)` make
variable when deciding which files to skip during syntax checking.

### New `package` Target

```
make package
```

Runs `clean` followed by a full build with `LINT=on SCAN=on`.

---

## Documentation Updates

- POD for `is_core` rewritten to clearly describe the "never-removed"
  requirement.
- POD for `--min-core-version` extended with a note about removed-from-core
  behaviour.
- New POD sections for `--file-list` and `--path` options.
- `--json` entry updated to document interaction with `--file-list`.
- Minor typo fixes (`sting` → `string`, duplicate `the the` → `the`).
- `README.md` regenerated from updated POD.

---

## Upgrade Notes

- Projects that depend on `Module::ScanDeps::Static` and set `--min-core-version`
  should be aware that the `is_core` semantics have tightened: modules
  previously considered core because their *removal* version exceeded
  `min_core_version` are now always reported as non-core. Dependency lists may
  grow slightly if any such modules are in use.
- The two new `CLI::Simple` sub-module dependencies (`CLI::Simple::Constants`
  and `CLI::Simple::Utils` ≥ 2.1.1) must be available. If you install from
  CPAN these will be pulled in automatically.