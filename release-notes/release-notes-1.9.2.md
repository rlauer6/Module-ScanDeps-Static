# Release Notes — Module::ScanDeps::Static 1.9.2

**Released:** Thu Jul 23 2026  
**Author:** Rob Lauer \<rclauer@gmail.com\>

---

## Overview

Version 1.9.2 is a substantial feature release that introduces
**three-tier dependency classification** (`requires` / `recommends` /
`suggests`), matching the relationship types defined by
[CPAN::Meta::Spec](https://metacpan.org/pod/CPAN::Meta::Spec). The
scanner can now automatically distinguish between unconditional hard
requirements, conditionally-guarded soft dependencies, and
eval-wrapped optional dependencies — and write each tier to a separate
output file in a single scan pass.

---

## New Features

### Three-Tier Dependency Classification

Dependencies discovered during scanning are now classified into one of three tiers:

- **`requires`** — bare, unconditional `use`/`require`, or
  `with`/`extends`/`parent`/`base` declarations.
- **`recommends`** — explicitly guarded dependencies judged to be
  important but not strictly required.
- **`suggests`** — eval-wrapped or weakly conditional optional
  dependencies.

Classification is based on structural analysis of the source code, not runtime behaviour.

### Eval Block Detection (`add_suggests`, `add_recommends`)

The parser now properly detects `eval { ... }` blocks (including
multi-line and `or die`/`or do { }` variants) and routes any
`require`/`use` found inside them to the `suggests` tier by
default. The brace-depth tracking correctly handles nested structures
and trailing `or do { }` clauses without sweeping unrelated code into
the eval body.

String-form `eval "..."` is also detected and routed to `suggests`.

### `## scandeps:` Annotation

Authors can explicitly declare the intended tier of an eval-wrapped
dependency with an inline comment:

```perl
eval { require Foo::Bar; };  ## scandeps: recommends

eval { require Foo::Bar; 1; } or die $@;  ## scandeps: suggests

eval {
    require Foo::Bar;
    1;
} or do {
    warn "Foo::Bar unavailable\n";
};  ## scandeps: recommends
```

The annotation must appear after the semicolon that terminates the
whole statement. An explicit annotation always overrides both the
structural default and `--eval-recommends`.

### New CLI Options

| Option | Description |
|--------|-------------|
| `--eval-recommends` | Classify unannotated eval-wrapped deps as `recommends` instead of `suggests` (default: off) |
| `--recommend-require`, `-R` | Route indented (non-eval) conditional `require` statements to the `recommends` tier instead of treating them as hard requirements or dropping them (default: off) |
| `--filter`, `-f` | Exclude modules that appear as `package` declarations within the scanned files, preventing intra-project packages from being reported as external dependencies |
| `--requires-file PATH` | Write the `requires` tier to `PATH` |
| `--recommends-file PATH` | Write the `recommends` tier to `PATH` |
| `--suggests-file PATH` | Write the `suggests` tier to `PATH` |
| `--cpan-file PATH` | Write a single cpanfile to PATH, combining all three tiers in native cpanfile DSL syntax |


### Moose `extends` Support

`extends 'Foo'` and `extends 'Foo', 'Bar'` are now recognised
alongside `with`, `use parent`, and `use base`, and receive identical
treatment as hard `requires` dependencies.

### Intra-Project Package Tracking (`--filter`)

`parse_line` now tracks every `package` declaration encountered across
the entire batch when `--file-list` is in use. When `--filter` is
active, any module name matching a tracked package is excluded from
all three tier outputs. The default for `--filter` is
context-dependent: **off** for a single file, **on** when
`--file-list` is given — but an explicit `--filter`/`--no-filter`
always wins.

### Conflict Detection (`warn_tier_conflicts`)

After scanning, the new `warn_tier_conflicts` method emits a warning
to `STDERR` for any module that appears in more than one tier
simultaneously (e.g. both `requires` and `recommends`, or both
`recommends` and `suggests`). The tiers themselves are left unmodified
— resolving the contradiction is left to the author.

### Tier File Output (`_write_tier_file`)

A new internal `_write_tier_file` method writes each tier to its
designated file path (set via `--requires-file`, `--recommends-file`,
`--suggests-file`). All three are always written as plain `module
version` text regardless of whether `--json` or `--raw` is also in
effect.

### Single-Pass Multi-Tier Scanning in the Makefile

The `Makefile` now produces `requires.raw`, `recommends.raw`, and
`suggests.raw` in a **single `scandeps-static` invocation**,
eliminating the need for separate scans per tier. A shared pattern
rule (`%: %.raw`) reconciles each raw scan result against the skip
list and previous run via `cmb filter`.

---

## Improvements

### Lazy Loading of Expensive Modules

`Module::CoreList`, `ExtUtils::MM`, `Pod::Usage`, and `Pod::Find` are
now loaded lazily (inside `require` blocks at point of use) rather
than at startup. This meaningfully reduces process startup time, which
matters when `scandeps-static` is invoked repeatedly across many
files.

### `Log::Log4perl` Removed

All debug and info logging via `Log::Log4perl` has been removed from
`Module::ScanDeps::Static`, further reducing load time and eliminating
the runtime dependency.

### `get_dependencies` / `format_json` / `format_text` Now Tier-Aware

All three methods accept a `tier` option (`require`, `recommends`, or
`suggests`) to select which dependency hash to format. The `perl`
version requirement is only attached to the `require` tier's output.

### `cmd_scan` Refactored

`cmd_scan` now delegates output formatting to `get_dependencies`, then
calls `_write_tier_file` for each of the three tier output files. The
previous approach of accumulating formatted strings across files has
been replaced with a single accumulated object that is formatted once
at the end.

---

## Deprecations

### `scandeps-static.pl`

The `scandeps-static.pl` wrapper script now prints a deprecation
notice to `STDERR` on every invocation:

```
Deprecated...use scandeps-static
```

The `scandeps-static` binary (without the `.pl` extension) is the
supported entry point going forward.

### `require Module::ScanDeps::Static::VERSION`

The explicit `require Module::ScanDeps::Static::VERSION` statements in
`FindRequires.pm` and `scandeps-static.pl` have been removed.

---

## Bug Fixes

- Brace-depth tracking in eval detection now correctly handles `eval {
  ... } or do { ... }` — previously a naive brace count would sweep
  the `or do {}` block into the eval body, potentially misclassifying
  unrelated code.
- Comment lines are now explicitly excluded from eval detection to
  prevent documentation examples (like the ones in the source itself)
  from being parsed as live code.
- `Progress::Any::Output::TermProgressBarColor` version in `cpanfile`
  corrected from `""` to `"0"`.

---

## Build System Changes

- `.gitignore`: Added `**/*.checked` and `**/*.raw` patterns.
- `Makefile`: `MD_UTILS` now resolves `markdown-render` (was
  `md-utils.pl`); `SCANDEPS` now resolves `scandeps-static` (was
  `scandeps-static.pl`); `recommends` and `suggests` added to `DEPS`;
  `*.raw` added to `CLEANFILES`.
- `perl.mk`: `PERLCRITIC_SEVERITY` (default `5`) and
  `PERLCRITIC_THEME` (default `pbp`) are now configurable via
  environment variables. Critic sentinel rules now use `set -eo
  pipefail` and `tee` to write output to the sentinel file while also
  displaying it. The `critic` convenience target now calls
  `check-syntax` explicitly and uses a `[[ -n ... ]]` guard instead of
  `test -n ... &&`.
- `update.mk`: The `post-update` target now merges any new entries
  from the bootstrapper's `gitignore` into the project's `.gitignore`
  automatically.
- `release-notes.mk`: Updated to invoke `cmb release-notes` instead of
  `bootstrapper release-notes`.

---

## New Tests

- `t/03-suggests-recommends.t` — tests for the new three-tier classification behaviour, including eval block detection, `## scandeps:` annotation parsing, and `--eval-recommends`/`--recommend-require` option handling.

---

## Documentation

The POD and `README.md` have been updated to document:

- **Dependency Tiers** — description of `requires`, `recommends`, and `suggests` and the rationale for not inferring `recommends` vs. `suggests` from code structure.
- **Structural Classification** — rules for when a dependency is classified into each tier.
- **The `## scandeps:` Annotation** — syntax and placement rules.
- **Conflicting Classifications** — what happens when a module appears in multiple tiers.
- **Self-Referential Modules** — how `--filter` works with `--file-list`.
- **Dynamic Module Loading** — explicit documentation of what the static scanner cannot see, and guidance on when to use `Module::Load` vs. plain `require`.
- Moose `extends` support added to the dependency detection description.
- All new CLI options documented in full.
