# consultologist-workflows

Workflow package sources for [Consultologist](https://app.consultologist.ai).
This repo is the **canonical authoring home** for repo-owned packages;
the app repo carries the engine that interprets them. Seeded from the app
repo (Consultologist-Blazor) on 2026-07-23; design in its
`docs/customizable-workflow/content-repos.md`.

| Package | What it is |
|---|---|
| `general` | The production consult workflow: one input, one assembled note. |
| `test/general` | The `general` workflow as the editor evolves it, at the newest format (specVersion 26): a nested name (`packages/test/general`), the SNOMED tool guidance read inline as a **snippet** by the four concept prompts (a migrated prelude), a slot-placed macro and an appended one on the note. A proving ground for the current format, not a clinical release. |
| `example-two-documents` | A demonstration of what specVersion 7 opened — two declared inputs (one optional) and two deliverables. Not intended for clinical use. |
| `example-conditional-documents` | A demonstration of what specVersion 8 opened — a typed date, an enum, a boolean, and two deliverables firing on different values of one *optional* enum, so leaving it unanswered produces nothing and the job is refused at start. Not intended for clinical use. |
| `example-structured-intake` | A demonstration of what specVersion 9 opened — an array of prior notes fanned per element, a patient object read by path (`patient.age >= 65`), a number driving an ordering comparison, an unconditional digest written only from the notes, and an index gated on `count()`. The fanned input is *optional* on purpose: leaving it empty shows the empty-fan refusal and the Failed job record it leaves — the digest has nothing to be written from. Not intended for clinical use. |
| `example-classifier-scope` | A demonstration of what specVersion 10 opened — a classifier node reads the referral and answers `in_scope`, `out_of_scope` or `needs_information`; three deliverables each fire on one answer (`node:scope == in_scope` …), so the package decides what to produce at the boundary rather than asking at intake. A plan fanned over two sections, or a one-section letter. Not intended for clinical use. |
| `example-v12-constructs` | A demonstration of everything specVersion 12 opened — an optional macro with a declared default the run may choose, a macro placed against a section, a closing macro carrying `{{profile:signature}}`, conditional macros gated on a tone classifier (match/case as declarations), a template node whose render IS its output, and two checks: the note's passes against its own extraction, the letter's fixed template text records a deterministic failure. Not intended for clinical use. |
| `example-conditional-sections` | A demonstration of what specVersion 27 opened — a flow node inside a `for`. Three loops: a `case` on each requested section's kind (an `array<object>` input) drafts narrative sections as prose and table sections as a table and skips an `omit` section by condition; an `if` with no `else` writes one patient-facing line for the narrative sections alone; an `if` over a folder of standing sections holds the billing section back unless `include_billing` is set. A closing node reads the loop's elements (`e.skipped`) to name what was left out; the record (storage 9) names every skipped item and its reason. Not intended for clinical use. |

## Contract

- One directory per package under `packages/` (`manifest.json`, `prompts/`,
  `snippets/`, `macros/`, optional `formats/`, optional `dag.mmd`; `schemas/`
  and `data/` are the layout below specVersion 25).
- The registry's layout — paths, CalVer, immutability, `latest.json` — is the
  contract published as `registry-layout.md` in
  [consultologist-provenance](https://github.com/Consultologist/consultologist-provenance);
  this repo's script and CI conform to it.
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
- `dag.mmd` is **derived** from `nodes` and `deliverables` — and, from
  specVersion 25, from the reads every prompt, snippet and macro text makes
  (engine #1227) — by the app's `WorkflowDagDiagram` and never authored by
  hand. Nothing regenerates or diffs it automatically; regenerate it whenever
  nodes, bindings, deliverables or their conditions change, or any prompt,
  snippet or macro read does:

  ```
  dotnet run -v q --file scripts/validate-workflow-package.cs -- <package-dir> --dag | sed -n '/^flowchart TD/,$p' > <package-dir>/dag.mmd
  ```

  The `sed` keeps the diagram alone: MSBuild writes restore and compiler
  warnings to stdout even at `-v q`, ahead of the `flowchart TD` line.

  The `-v q` is load-bearing: MSBuild writes build warnings to stdout, so
  a redirect without it captures them into the diagram.
- **Migrating a package to specVersion 25** runs the app repo's offline runner
  over the package directory — a dry run first, then `--write`:

  ```
  dotnet run -v q --file scripts/migrate-workflow-package.cs -- <package-dir>
  dotnet run -v q --file scripts/migrate-workflow-package.cs -- <package-dir> --write
  ```

  It stages the package to 24 the editor's way (a prelude becomes a macro
  composed before its prompts), runs the library's 24 → 25 rewriter, writes
  the files, `manifest.json` and a regenerated `dag.mmd`, and prints the
  validator's verdict. What it cannot write it names as errors: a macro that
  is still placed on an output needs an `instruction`, a custom format needs a
  description. Make those edits, re-run the validator, bump the CalVer, tag.
- **Migrating a 25 package to specVersion 26** is the same runner's second
  stage (`--to 26`): the library's 25 → 26 rewriter folds each aggregated fan
  into a `for` node, keys every gate `if`, names each node's prompt file,
  moves a snippet's or macro's label, instruction and gate into the file's
  JSON header (a snippet that had no label gets one invented from its id,
  named in a notice — review it), and writes the files, `manifest.json` and
  `dag.mmd` once the 26 package validates:

  ```
  dotnet run -v q --file scripts/migrate-workflow-package.cs -- <package-dir> --to 26
  dotnet run -v q --file scripts/migrate-workflow-package.cs -- <package-dir> --to 26 --write
  ```

## Publishing (CI-only)

Tag `general-vYYYY.MM.N` (matching the manifest's version) → the publish
workflow authenticates to Azure via GitHub OIDC (no stored secrets) and
runs `scripts/publish-workflow-package.sh` against the public registry,
then smoke-checks the published artifacts anonymously. Human registry
writes are retired; the CI identity is the registry's only writer.

## Licence

The packages in this repository — manifests, prompts, standards, data and
schemas — are licensed **[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)**
— © 2026 Tauheed Elahee. Read them, cite them, fork and modify them for
research and trial, and share what you make under the same terms, with
attribution. Not for commercial use *under this licence*. The licence file
travels with every published version (`{name}/{version}/LICENSE`) from the
first publish after 2026-08-25; earlier versions carry none and are covered
by this file all the same.

**Consultologist clients hold a licence that goes beyond this one.** Every
client may use these packages and their forks commercially — inside the app, and in their own
environment outside it — and holds the copyright in what they author. That
permission is part of the client agreement, not this file; this licence is
the public default for everyone else. Anyone who needs more than it grants
can ask.

What it does not reach:

- **The engine.** Consultologist-Blazor is separately licensed (PolyForm
  Strict); nothing here grants a right to run it.
- **The format.** A package that conforms to the published package format is
  not a derivative of these examples unless it copies them; the format's own
  documents are licensed by their registry.
- **Patents and trademarks.** None are granted.

GitHub shows this repository's licence as "Other": it classifies no
NonCommercial licence.
