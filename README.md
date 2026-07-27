# consultologist-workflows

Workflow package sources for [Consultologist](https://app.consultologist.ai).
This repo is the **canonical authoring home** for repo-owned packages;
the app repo carries the engine that interprets them. Seeded from the app
repo (Consultologist-Blazor) on 2026-07-23; design in its
`docs/customizable-workflow/content-repos.md`.

| Package | What it is |
|---|---|
| `general` | The production consult workflow: one input, one assembled note. |
| `example-two-documents` | A demonstration of what specVersion 7 opened — two declared inputs (one optional) and two deliverables. Not intended for clinical use. |

## Contract

- One directory per package under `packages/` (`manifest.json`, `prompts/`,
  `schemas/`, `data/`, optional `dag.mmd`).
- Versions are CalVer (`vYYYY.MM.N`), declared in `manifest.json`, and
  **immutable once published** — the registry refuses re-publishing an
  existing version; `{name}/latest.json` is the only mutable pointer.
- The app's server-side validator remains the authority for account forks;
  CI here validates structure (manifest parse, CalVer, file closure,
  version-not-yet-published) before any publish. It does **not** read
  `specVersion`, traverse `nodes`, or check that bindings, results and
  declared inputs resolve — run a manifest through the app's validator
  before tagging, since the registry accepts what CI here waves through.
- `dag.mmd` is **derived** from `nodes` by the app's `WorkflowDagDiagram`
  and never authored by hand. Nothing regenerates or diffs it
  automatically; regenerate it whenever nodes or bindings change.

## Publishing (CI-only)

Tag `general-vYYYY.MM.N` (matching the manifest's version) → the publish
workflow authenticates to Azure via GitHub OIDC (no stored secrets) and
runs `scripts/publish-workflow-package.sh` against the public registry,
then smoke-checks the published artifacts anonymously. Human registry
writes are retired; the CI identity is the registry's only writer.
