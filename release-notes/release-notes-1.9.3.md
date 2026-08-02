# Release Notes: Module::ScanDeps::Static 1.9.3

**Release Date:** Sun Aug 2, 2026
**Distribution:** Module-ScanDeps-Static
**Version:** 1.9.3

---

## Overview

This release introduces pragma-awareness across all dependency tiers
and extends the `## scandeps:` annotation to support explicit
`requires` classification. The strongest dependency tier now always
wins when the same module appears in multiple tiers, ensuring that a
hard requirement correctly supersedes any softer listing without
developer intervention.

---

## New Features

### Pragma Detection (`is_pragma`)

A new `is_pragma` method has been added to
`Module::ScanDeps::Static`. Perl built-in pragmas (such as `strict`,
`warnings`, `feature`, `utf8`, `lib`, and others) are now recognized
and silently excluded from all dependency tiers. Previously, pragmas
could appear as false-positive dependencies in scan output.

The full list of recognized pragmas:

```
strict warnings vars lib feature utf8 bytes integer diagnostics
sort subs re mro locale open less filetest attributes autouse
```

### `## scandeps: requires` Annotation Support

The inline annotation comment now accepts `requires` as a valid tier
classifier in addition to the previously supported `recommends` and
`suggests`:

```perl
eval { require Some::Module; };  ## scandeps: requires
```

This allows a developer to explicitly promote an eval-wrapped
dependency to a hard requirement when the structural guard does not
reflect the module's true importance to the project.

### Tier Precedence Enforcement ("Strongest Tier Wins")

When a module is encountered across multiple dependency tiers during a
scan, the strongest tier now always supersedes softer listings:

- **`add_require`**: Deletes the module from both `recommends` and
  `suggests` before registering it as a hard requirement.
- **`add_recommends`**: Returns early (no-op) if the module already
  exists in `requires`; deletes from `suggests` before registering as
  a recommendation.
- **`add_suggests`**: Returns early (no-op) if the module already
  exists in either `requires` or `recommends`.

This eliminates the possibility of a module appearing in a weaker tier
after it has already been classified as a stronger dependency.

---

## Bug Fixes

- Pragmas are no longer incorrectly recorded as module dependencies in
  any tier (`requires`, `recommends`, or `suggests`).
- A module promoted to `requires` via `## scandeps: requires` now
  correctly removes it from any softer tier it may have previously
  been assigned to.

---

## Tests

- **`t/04-pragma-and-tiers.t`** (new): Test suite covering pragma
  exclusion and tier precedence behaviour across `add_require`,
  `add_recommends`, and `add_suggests`.

---

## Build System Changes

- **`.includes/perl.mk`**: Updated by `CPAN::Maker::Bootstrapper`. The
  `critic` target now passes `--theme` and `--severity` flags
  consistently to `perlcritic` for both modules and scripts.
- **`Makefile`**: Updated by `CPAN::Maker::Bootstrapper`.
  - `cpanfile` generation refactored to use intermediate targets
    `cpanfile.requires`, `cpanfile.suggests`, and
    `cpanfile.recommends`, allowing each dependency tier to be written
    independently and then concatenated.
  - `MIN_PERL_VERSION_FLAG` now guards against a missing
    `buildspec.yml` before attempting to read from it.
  - `README.md` generation is now non-fatal (`|| true`) when
    `MD_UTILS` encounters an error.
  - `deps.mk` now depends on built source files rather than `.pm.in` templates.
  - `build-ci` target mounts the current working directory into the
    Docker container and passes the `REPO` environment variable.
  - `test-requires.raw` filtering simplified; `cmb filter` is now
    always called unconditionally.
  - `.INTERMEDIATE` declarations added for `requires.raw`,
    `recommends.raw`, `suggests.raw`, and `test-requires.raw`.

---

## Upgrade Notes

No breaking API changes. The new tier-precedence behaviour is
automatic and requires no changes to existing code or
configuration. Developers who rely on a module appearing
simultaneously in multiple tier output files should be aware that the
stronger tier will now exclusively claim the module.
