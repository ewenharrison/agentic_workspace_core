# Agentic Workspace Core

`agentic_workspace_core` is a reusable file-system framework for running durable, project-based work with a human and an LLM coding agent.

It also supports an optional top-level personal-context layer at `profile/` for durable user-level preferences, writing style, and other cross-project context.

It is designed for people who want:

- one folder per project
- a clear split between trusted memory and provisional agent output
- lightweight session rehydration
- reusable templates for notes, source summaries, and project state

## Quick Start

1. Fork, clone, or copy this repository into a private working repository.
2. Open the repository root in an IDE such as VS Code.
3. Start a filesystem-capable LLM coding CLI, such as Codex CLI or Claude Code, in the IDE terminal.
4. Enter an ordinary-language prompt describing the work. The agent should read the repo instructions and operate on the files directly.

### Build Your Profile (Optional)

Before creating projects, you can build the optional personal-context layer from material you choose to provide, such as:

- a current CV, resume, biography, or biosketch
- representative writing samples
- saved memories exported from ChatGPT, Claude, or another LLM
- an explicit list of recurring preferences or working conventions

Place source copies under `profile/sources/files/`, or register a secure external location in `profile/sources/index.md` when the material should not be committed to Git. Then use:

```text
Build my personal profile from the material under profile/sources/files/. It includes a CV, writing samples, and saved memories exported from other LLMs. Follow workspace/repo/profile-onboarding.md. Preserve the originals, inventory the sources, distinguish facts from preferences and model inferences, flag conflicts or sensitive material, and draft proposed updates in profile/working/. Do not update the durable profile files until I approve the proposal.
```

The agent should prepare an attributed proposal rather than copying whole source documents into active memory. After review, approved material can be distilled into `profile/context.md`, `identity.md`, `preferences.md`, `writing_style.md`, `relationships.md`, and `active_notes.md`. See [Personal Profile Onboarding](./workspace/repo/profile-onboarding.md) for the full workflow and privacy guardrails.

A useful first project prompt is:

```text
Read README.md and workspace/repo/shared-procedures.md. Initialise project sample-project. Explain the trusted and provisional folder boundaries, then tell me what you need from me before making changes.
```

Prompts do not need special syntax. They work best when they make five things clear:

```text
Context: the project to initialise or the repo procedure to use
Task: the concrete action or question
Inputs: the files, URLs, criteria, or source set to use
Constraints: approval boundaries, exclusions, and actions that require a pause
Output: the file or decision you expect, including its intended folder
```

Not every prompt needs all five labels. Once a project is initialised, a short follow-up such as `Update the synthesis with this paper, but keep it in working` is usually enough.

Example prompts:

```text
Create a new project called medication-safety using the repo's project scaffolder. Set its initial goal to review interventions that reduce prescribing errors. Do not add agent-authored material to approved/. Finish by showing me the new project structure and open questions.
```

```text
Initialise project medication-safety. Read its current memory and approved index, then summarise where we left off and complete the next action. Keep new analysis in a date-prefixed file under working/ and update memory.md when finished.
```

```text
Initialise project medication-safety. Import the PDF at <path-to-file> as a source. Preserve the original under sources/files/, create a dated source note in working/, distinguish direct evidence from interpretation, and do not promote anything to approved/ yet.
```

```text
Initialise project medication-safety. Help me design a reproducible PubMed search protocol for medication-review interventions in older adults. Draft the protocol in working/, include eligibility criteria and proposed search terms, and stop for my approval before running the search.
```

```text
Initialise project medication-safety. Synthesize the approved source notes into a draft briefing in working/. Use only supported claims, cite the source notes, identify disagreements and evidence gaps, and recommend what should be reviewed before promotion.
```

```text
Independently review the draft application at <path-to-document> against the criteria at <path-to-criteria>. Follow workspace/repo/independent-review-protocol.md. Record your findings before reading any previous review, classify each issue by actionability, and save a dated review report in the project's working/ folder.
```

Useful control phrases include `do not write yet`, `keep this in working`, `use approved sources only`, `stop before external action`, and `ask before committing or pushing`. These make the human approval boundary explicit without requiring a specialised command language.

## What This Repo Is

This repo contains the reusable structure only.

It is intended to be copied, forked, or adapted into a private working repo where real projects live.

The design centres on four ideas:

- `memory.md` is the fast briefing file for resuming work
- `project.md` holds slower-changing goals, decisions, and governance
- `approved/` and `auto/` stay separate so reviewed knowledge and exploratory agent output do not get mixed together
- `approved/index.md` is the navigation surface for reviewed material

For a quick visual map of the folder structure, see [STRUCTURE.md](./STRUCTURE.md).

## Folder Layout

Short version:

```text
sources -> working -> approved
 raw       Tier 1      Tier 1
 inputs    draft       trusted

auto = Tier 2 provisional side lane
```

The subtle but important point is that `working/` is part of Tier 1. It is the pre-approved, human-in-the-loop workspace. `approved/` is also Tier 1, but after explicit approval. `auto/` is the Tier 2 autonomous lane and is provisional until reviewed.

```text
profile/
  init.md
  context.md
  identity.md
  preferences.md
  writing_style.md
  relationships.md
  active_notes.md
  approved/
    index.md
    framing/
    sources/
    syntheses/
    outputs/
  auto/
    index.md
  working/
    index.md
  logs/
    activity.md
  sources/
    index.md
    files/
    links/
workspace/
  _templates/
  projects/
    sample-project/
  registry/
  repo/
  workflows/
scripts/
README.md
```

## Core Concepts

### `memory.md`

The first file to open when resuming a project.
It should stay compact and answer:

- what are we doing?
- what claims are we carrying forward?
- what is still open?
- what should happen next?

### `profile/context.md`

The first file to open when loading user-level personal context.
Use it for:

- durable cross-project facts
- writing or collaboration preferences
- active notes that matter across current work
- guardrails around how personal context should be used

### `project.md`

The slower-moving project record.
Use it for:

- overview
- scope
- goals
- active tasks
- decisions
- open questions
- important sources

### `working/`

The pre-approved Tier 1 workspace.
Use it for:

- draft source notes and summaries
- concept notes, search strategies, figures, and export-ready working documents
- material that has been structured but not yet promoted into canonical memory

Search strategies and executed search results should be stored as separate working files so it is clear whether a search has actually been run.

Example pattern:

- `working/YYYY-MM-DD-search-strategy-<topic>.md`
- `working/YYYY-MM-DD-search-results-<topic>.md`

Every non-placeholder file created in `working/` should begin with `YYYY-MM-DD-`.

### `workspace/runs/agent-runs.md`

The cross-project control surface for agent runs.
Use it to track:

- cloud or local agent runs
- input files or prompts
- generated pull requests or notes
- dependencies between scout, search, and synthesis steps
- final decisions such as merged, closed, superseded, or promoted

GitHub remains the audit layer, but the run register should be the human-readable workflow state.

### `approved/`

The trusted layer.
Use it for reviewed source notes and durable project knowledge.

New projects should organise approved material as:

- `approved/index.md` for the main approved navigation map
- `approved/framing/` for approved framing or concept notes
- `approved/sources/` for approved source notes
- `approved/syntheses/` for approved synthesis notes
- `approved/outputs/` for completed or agreed deliverables such as final grants, manuscripts, cover letters, policy briefs, reviewer packs, and circulation-ready documents

`approved/` means human-reviewed canonical memory. Raw user-provided files can live in `sources/`, but an agent summary of them is not approved until reviewed or explicitly requested as an approved note.

### `auto/`

The exploratory lane.
Use it for agent-generated summaries, rough synthesis, and provisional material that has not yet been promoted.

Many projects will have little or no active Tier 2 material. A sparse `auto/` folder is expected when the project is being run mostly through Tier 1.

## Recommended Workflow

1. Create a new project from the sample structure.
2. Add material to the project.
3. Summarise or structure it into `working/`, `approved/`, or `auto/` depending on trust level.
4. Keep `memory.md` current so future sessions can restart quickly.
5. Promote only reviewed material into the canonical layer.

## Included in Core

- reusable templates
- shared repo procedures
- workflow notes
- a sample project
- utility scripts that are generic enough to reuse
- optional Slack and Teams webhook posting helpers

## Not Included in Core

- real project folders
- private notes or source material
- local configuration and secrets
- project-specific operational details that are not general defaults
- private email or note-capture routing details

## Cloud Tier 2 Workflow

Core includes a manual-only GitHub Actions workflow for cloud-triggered Tier 2 maintenance:

- `.github/workflows/tier2-cloud-maintenance.yml`
- `scripts/run-tier2-cloud-task.ps1`

It is intentionally exported without a scheduled trigger.

To use it:

1. Add `OPENAI_API_KEY` as a repository secret.
2. Optionally add repository variables:
   - `OPENAI_MODEL`
   - `OPENAI_REASONING_EFFORT`
3. Trigger `Tier 2 Cloud Maintenance` manually from the Actions tab.

If you want automatic runs in your own private repo, add a `schedule:` block to the workflow after forking or copying the framework.

## Suggested Use

- keep this repo as the clean framework
- maintain your real work in a separate private repo
- promote framework improvements back into core only when they are reusable

## Session Initialisation

Use:

`Initialise project <project-slug>`

The standard read order is:

1. `profile/context.md` if present
2. `workspace/repo/shared-procedures.md`
3. task-relevant repo procedures, such as `workspace/repo/literature-search-protocol.md` for literature, web, journal, or URL access work, `workspace/repo/signal-review-protocol.md` for repeated signal review, or `workspace/repo/corpus-retrieval-protocol.md` for corpus retrieval
4. `memory.md`
5. `project.md`
6. `approved/index.md`
7. `auto/index.md`
8. `logs/activity.md`

## Collaboration Updates

Core includes optional webhook helpers for collaborator-facing project updates:

- Teams updates: `scripts/post-teams-update.ps1`, reading `collab/teams-update.md`
- Slack updates: `scripts/post-slack-update.ps1`, reading `collab/slack-update.md`
- Long Slack file posts: `scripts/post-slack-file.ps1`

Store real webhook URLs outside git in `config/teams-webhook-url.txt`, `config/slack-webhook-url.txt`, `config/slack-webhooks.json`, or the matching environment variables. The files ending in `.example` are placeholders only.

## Evidence And Citation Discipline

For fact-bearing drafts, use confirmed sources only: local files, extracted PDFs, executed search-results notes, official pages, DOI/PubMed/Crossref records, or other checked records. If a claim lacks support, mark it as `[source needed]`, search, ask, or remove it.

When triaging sources, note whether the user or a known collaborator appears connected to the source. That relationship can change interpretation, but uncertain name matches should stay marked as unclear.

For repeated signal streams, use the signal-review protocol: collect a bounded read-only packet, write a date-prefixed digest, validate it, and advance completed state only after validation. For corpus retrieval, use the corpus-retrieval protocol: start with an access smoke test, keep credentials out of the repo, maintain a retrieval manifest, and treat automated extraction or coding as provisional until reviewed.

To load only the personal-context layer, use:

`Initialise personal context`

To create or materially refresh that layer from user-provided sources, use:

`Build personal profile`

When the `profile/` layer is in use, you can also say:

- `Save this to personal context`
- `Save this to personal context as approved`
- `Do not use personal context for this task`

## Writing Convention

Prefer British English spelling in repo documentation where practical.

## Current Status

This repo is the reusable scaffold for the broader Agentic Memory approach.
It is meant to stay small, clear, and safe to share.
