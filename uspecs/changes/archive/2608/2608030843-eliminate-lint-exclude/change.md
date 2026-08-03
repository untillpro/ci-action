---
change_id: 2607311325-eliminate-lint-exclude
type: ci
scope: [ci, linting]
breaking: true
issue_url: https://untill.atlassian.net/browse/AIR-4329
---

# Change request: Removal of lint exclusion configuration

Refs:

- [AIR-4329: ci-action: eliminate lint_exclude setting](./issue-AIR-4329.md)

## Why

Explicit lint exclusions are no longer used after the referenced Voedger change reaches production. Removing this obsolete configuration keeps CI linting simpler and avoids exposing settings that no longer affect the checks.

## What

Linting no longer requires contributors or CI consumers to configure explicit exclusions:

- CI lint execution no longer accepts explicit path exclusions.
- Repository consumers no longer provide lint exclusion settings through environment variables or command arguments.

## How

Decisions:

- Make repository-owned `.nolint` markers, including the existing ancestor-marker inheritance, the sole project-configurable mechanism for skipping discovered Go modules.
- Remove `lint_exclude` as a public input from both reusable workflow entry points and stop forwarding exclusion environment values or command-line arguments through the linter script chain; do not retain a deprecated compatibility path.
- Preserve recursive Go-module discovery, built-in directory pruning, linter installation, failure aggregation, and `.nolint` summary reporting.
- Verify the reusable-workflow contract and shell execution path together, including repository-wide removal of the legacy configuration and continued `.nolint` inheritance.

Assumptions:

- Workflow consumers that still require lint exclusions will migrate those exclusions to repository-owned `.nolint` markers before adopting the revised reusable workflows.

Out of scope:

- Adding or relocating `.nolint` markers in consumer repositories.
- Changing `.nolint` discovery semantics or other linter behavior.

References:

- [main reusable workflow input and linter invocation](../../../../../.github/workflows/ci.yml)
- [pull-request workflow input forwarding](../../../../../.github/workflows/ci_pr.yml)
- [linter bootstrap and delegation](../../../../../scripts/run-linters.sh)
- [recursive module discovery and exclusion semantics](../../../../../scripts/lint-all.sh)
- [public reusable-workflow examples](../../../../../README.md)
- [completed Voedger migration to `.nolint` markers](https://github.com/voedger/voedger/commit/97ee1cd59b7306c74e35a9136893b02f14f0449d)

## Provisioning and configuration

- [x] update: [main reusable workflow](../../../../../.github/workflows/ci.yml): remove the `lint_exclude` workflow-call input and invoke the linter chain without exclusion environment values or arguments (manual edit - no CLI available)
- [x] update: [pull-request reusable workflow](../../../../../.github/workflows/ci_pr.yml): remove the `lint_exclude` workflow-call input and stop forwarding it to the main reusable workflow (manual edit - no CLI available)

## Construction

- [x] update: [scripts/lint-all.sh](../../../../../scripts/lint-all.sh)
  - remove the `--exclude` usage contract, argument parsing, path normalization, module filtering, and explicit-exclusion summary output
  - retain `.nolint` ancestor detection as the only configurable exclusion path while preserving module discovery, built-in directory pruning, failure aggregation, and summary behavior
- [x] update: [scripts/run-linters.sh](../../../../../scripts/run-linters.sh)
  - invoke `lint-all.sh` without forwarding command-line arguments
- [x] update: [README.md](../../../../../README.md)
  - remove `lint_exclude` from the main and pull-request reusable-workflow examples
  - document empty `.nolint` marker files as the supported way to skip a directory and its descendant Go modules
- [x] verify: lint exclusion removal and retained marker behavior
  - confirm runtime files and public documentation contain no `lint_exclude`, `LINT_EXCLUDE`, or `--exclude` references
  - exercise `lint-all.sh` with isolated Go-module fixtures and a stubbed linter to confirm unmarked modules are scanned while modules beneath a `.nolint` marker are skipped
