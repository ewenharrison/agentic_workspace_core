# Core Promotion Workflow

Use this file to manage what should move from the private live repo into `agentic_workspace_core`.

## Purpose

The private repo is the proving ground.
The core repo is the reusable public-safe framework.

Changes should usually be developed and tested here first, then promoted only once they feel stable across real project use.

## Promotion Rule

Promote a change to `agentic_workspace_core` when it:

- improves the workflow for more than one project
- is not tied to a specific domain, source, collaborator, or institution
- does not expose private project content
- is stable enough that you would want it in a starter version of the system

Keep a change private when it:

- only helps one project
- includes real project notes, sources, or sensitive context
- includes real `profile/` personal-context content
- includes generated Tier 2 notes from live project work
- is still experimental or likely to change again soon
- reflects a personal preference that should not become a default

## Non-Promotion Rule

Never promote these into `agentic_workspace_core`:

- specific live project content
- generated Tier 2 notes from live runs
- the live `profile/` content from this private repo

## Working Rhythm

1. Prototype a change in the private repo.
2. Let it survive at least one real use case where possible.
3. Record it in [core-candidate-changes.md](./core-candidate-changes.md).
4. Mark it as:
   - `Promote now`
   - `Watch`
   - `Keep private`
5. When ready, export the framework-only subset with:

`powershell -ExecutionPolicy Bypass -File .\scripts\export-agentic-memory-core.ps1`

## Agent Behaviour

When making repo-level improvements, the agent should:

- decide whether the change looks `core-worthy`
- add or update an entry in [core-candidate-changes.md](./core-candidate-changes.md)
- include a short recommendation on whether to promote now or wait
- avoid marking project-specific content as a core candidate

## Suggested Commit Prefixes

- `core:` reusable framework change that is a likely promotion candidate
- `repo:` private operational change for this live repo
- `project:` change tied to one specific project

Examples:

- `core: add project init bootstrap file`
- `core: refine memory snapshot structure`
- `repo: add export script for public-safe core bundle`
- `project: add domain-specific landscape note`

## Export Scope

The export script currently treats these as core material:

- `README.md`
- `STRUCTURE.md`
- `workspace/_templates/`
- `workspace/repo/`
- `workspace/workflows/`
- `workspace/registry/`
- `workspace/projects/sample-project/`
- selected generic scripts

Real project folders under `workspace/projects/` are not exported unless explicitly added to the allowlist.

The top-level `profile/` layer is now considered eligible for promotion to core as framework functionality, but exported content should remain template or example material rather than real personal-context data.

## Current Promotion Checklist: `profile/` Layer

Use this checklist when promoting the personal-context layer into `agentic_workspace_core`.

### Framework Decisions To Promote

- [x] Treat the top-level `profile/` layer as a core-supported optional feature.
- [x] Treat `profile/context.md` as the quick-start file for personal context.
- [x] Support `Initialise personal context` as a standard command.
- [x] Support loading `profile/context.md` before project files during `Initialise project <project-slug>` when the layer exists.
- [x] Keep the personal-context layer optional rather than mandatory.

### Documentation Changes Needed In Core

- [x] Promote the updated `README.md` wording from `README.core.md` so core documents:
  - the existence and purpose of `profile/`
  - the expected high-level `profile/` layout
  - the role of `profile/context.md`
  - the personal-context command surface
- [x] Promote the updated repo procedures in:
  - `workspace/repo/session-init.md`
  - `workspace/repo/shared-procedures.md`
- [ ] Ensure public-facing docs state clearly that `profile/` is for durable user-level context and should be used selectively.
- [ ] Ensure public-facing docs state clearly that real personal-context content should never be exported from a private repo into core.

### Safe Export Changes Needed

- [ ] Do not export the live private `profile/` folder as-is.
- [x] Create a sanitized core-safe `profile/` template set containing placeholder/example files only:
  - `profile/init.md`
  - `profile/context.md`
  - `profile/identity.md`
  - `profile/preferences.md`
  - `profile/writing_style.md`
  - `profile/relationships.md`
  - `profile/active_notes.md`
  - `profile/approved/index.md`
  - `profile/auto/index.md`
  - `profile/logs/activity.md`
  - `profile/sources/files/.gitkeep`
  - `profile/sources/links/.gitkeep`
- [x] Decide whether those sanitized files live:
  - directly in the tracked top-level `profile/` folder in core, or
  - in a separate template/staging location that the export script maps into `profile/`
- [x] Update `scripts/export-agentic-memory-core.ps1` so it exports the sanitized `profile/` framework files, not real personal data.
- [x] Verify that the export still rewrites any `*.core.md` files to public names correctly after the `profile/` addition.

### Quality Checks Before Promotion

- [ ] Confirm that the core bundle contains no real names, private relationships, personal preferences, or imported personal notes from the live repo.
- [ ] Confirm that the profile docs make privacy boundaries explicit.
- [ ] Confirm that a fresh user could understand when to use `profile/` versus `workspace/projects/`.
- [ ] Confirm that the optional `profile/` layer does not break the project-only workflow for users who do not want personal context.

### Recommended Implementation Order

1. Create sanitized `profile/` template/example files for core.
2. Update core docs and repo procedure files to describe the feature.
3. Update the export script allowlist and mapping logic.
4. Run the export and inspect the generated core bundle for privacy leaks or path issues.
5. Only then treat the `profile/` layer as fully promoted in practice.
