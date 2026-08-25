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
| `example-conditional-documents` | A demonstration of what specVersion 8 opened — a typed date, an enum, a boolean, and two deliverables firing on different values of one *optional* enum, so leaving it unanswered produces nothing and the job is refused at start. Not intended for clinical use. |
| `example-structured-intake` | A demonstration of what specVersion 9 opened — an array of prior notes fanned per element, a patient object read by path (`patient.age >= 65`), a number driving an ordering comparison, an unconditional digest written only from the notes, and an index gated on `count()`. The fanned input is *optional* on purpose: leaving it empty shows the empty-fan refusal and the Failed job record it leaves — the digest has nothing to be written from. Not intended for clinical use. |

## Contract

- One directory per package under `packages/` (`manifest.json`, `prompts/`,
  `schemas/`, `data/`, optional `dag.mmd`).
- Versions are CalVer (`vYYYY.MM.N`), declared in `manifest.json`, and
  **immutable once published** — the registry refuses re-publishing an
  existing version; `{name}/latest.json` is the only mutable pointer.
- CI here runs **two** validations before any publish. The structural one
  (manifest parse, CalVer, file closure, version-not-yet-published) is inline
  in `validate.yml`. The **engine** one (#185) is
  `scripts/validate-with-engine.sh`, which checks out the app repo with its
  agents submodule and runs the same `WorkflowPackageValidator.Validate` the
  registry runs on every account publish — `specVersion`, node and binding
  rules, reachability, strict template rendering, and schema matching against
  the output-contract catalog. Since #449 the app checkout is the commit the
  **deployed** engine reports at `GET /api/Public/Engine`, so "passed engine
  validation" is a statement about what will run; `main` is used only when
  that endpoint cannot say, and the run's summary names which it was.

  **Errors fail; warnings are annotated and do not.** That is what the app's
  publish already does, and a package must not be publishable through one door
  and refused by the other.

  To run the engine validator yourself before tagging, from the app repo:

  ```
  dotnet run -v q --file scripts/validate-workflow-package.cs -- <package-dir>
  ```

  or from here, against a sibling checkout:

  ```
  ./scripts/validate-with-engine.sh ../app/Consultologist-Blazor packages/<name>
  ```

  Until #185 this repo's CI checked structure only, and the README said so —
  the registry accepted what CI waved through, and the failure surfaced later
  at pin resolve as "registry unavailable", against an immutable version.
- `dag.mmd` is **derived** from `nodes` and `results` by the app's
  `WorkflowDagDiagram` and never authored by hand. Nothing regenerates or
  diffs it automatically; regenerate it whenever nodes, bindings,
  deliverables or their conditions change:

  ```
  dotnet run -v q --file scripts/validate-workflow-package.cs -- <package-dir> --dag > <package-dir>/dag.mmd
  ```

  The `-v q` is load-bearing: MSBuild writes build warnings to stdout, so
  a redirect without it captures them into the diagram.

## Publishing (CI-only)

Tag `general-vYYYY.MM.N` (matching the manifest's version) → the publish
workflow authenticates to Azure via GitHub OIDC (no stored secrets) and
runs `scripts/publish-workflow-package.sh` against the public registry,
then smoke-checks the published artifacts anonymously. Human registry
writes are retired; the CI identity is the registry's only writer.
