# Workspace Structure

This workspace has a small number of repeated folders. The main point is that `working/` and `approved/` are both Tier 1; they differ by review status.

## Project Map

```text
workspace/projects/<project>/
  sources/      raw inputs: PDFs, DOCX files, copied webpages, links, snapshots

  working/      Tier 1, pre-approved
                human-in-the-loop drafts, active packets, decision notes,
                search results, provisional source notes, and working outputs

  approved/     Tier 1, approved/canonical
                material the user has explicitly approved for durable reuse:
                framing, source notes, syntheses, final outputs

  auto/         Tier 2, autonomous/provisional
                agent-generated notes and exploratory synthesis; useful,
                but not trusted until reviewed or promoted

  memory.md     quick session briefing
  project.md    slower project structure, goals, and governance
  logs/         activity history
```

## Personal Context Layer

The optional `profile/` layer holds selective user context that is useful across projects. It follows the same raw, working, approved, and autonomous distinction without turning the whole personal archive into active memory.

```text
profile/
  sources/       user-provided originals, secure pointers, and provenance index
  working/       human-in-the-loop inventories and proposed profile updates
  approved/      reviewed source notes supporting durable profile content
  auto/          autonomous or exploratory observations; provisional

  context.md     compact cross-project briefing
  identity.md    stable user-level facts
  preferences.md recurring working preferences
  writing_style.md
                  source-linked writing guidance
  relationships.md
                  minimal recurring relationship context
  active_notes.md
                  temporary cross-project context
```

Use `workspace/repo/profile-onboarding.md` when constructing or materially refreshing this layer. Raw imports do not become durable profile memory until reviewed.

## Control Plane

`memory.md`, `project.md`, and `logs/` are not evidence tiers. They are the project control plane:

- `memory.md`: fast current-state briefing for future sessions.
- `project.md`: slower-changing scope, workflow, and decisions.
- `logs/activity.md`: what changed and when.

## Raw Sources

`sources/` is not Tier 1 or Tier 2. It is the raw evidence layer. Files can be used to create Tier 1 working notes, Tier 1 approved notes, or Tier 2 provisional notes.

## Tier 1

Tier 1 means human-in-the-loop.

- `working/`: material is being shaped, assessed, or drafted but has not become canonical.
- `approved/`: material has been explicitly accepted as reliable project memory or as a final agreed output.

Promotion is a deliberate act: move or copy the final item into `approved/`, update `approved/index.md`, and update links from `memory.md` or `project.md` if needed.

## Tier 2

Tier 2 means agentic/autonomous.

`auto/` is for speed and coverage. It is useful for exploratory scans, machine-generated summaries, and provisional synthesis, but it is not canonical. At the moment, this repo mostly uses Tier 1, so many `auto/` folders are intentionally sparse.

## Short Version

```text
sources -> working -> approved
 raw       Tier 1      Tier 1
 inputs    draft       trusted

auto = Tier 2 provisional side lane
```
