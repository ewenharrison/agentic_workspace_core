# Project Registry

Use this file as the top-level directory of all projects in the memory system.

## Projects

- [sample-project](../projects/sample-project/project.md): Example project showing the two-tier structure.

Add real projects here in your private working repo.

## Project Creation Pattern

For each new project, create:

- `workspace/projects/<project-slug>/init.md`
- `workspace/projects/<project-slug>/memory.md`
- `workspace/projects/<project-slug>/project.md`
- `workspace/projects/<project-slug>/approved/index.md`
- `workspace/projects/<project-slug>/approved/framing/`
- `workspace/projects/<project-slug>/approved/sources/`
- `workspace/projects/<project-slug>/approved/syntheses/`
- `workspace/projects/<project-slug>/approved/outputs/`
- `workspace/projects/<project-slug>/auto/index.md`
- `workspace/projects/<project-slug>/auto/autonomous-lane-policy.md` when Tier 2 is enabled proactively
- `workspace/projects/<project-slug>/logs/activity.md`
- `workspace/projects/<project-slug>/collab/teams-update.md` when Teams sharing is used
- `workspace/projects/<project-slug>/sources/files/`
- `workspace/projects/<project-slug>/sources/links/`
- `workspace/projects/<project-slug>/working/`

## Folder Meaning

- `sources/`: raw input layer, such as PDFs, DOCX files, copied webpages, links, and snapshots.
- `working/`: Tier 1 pre-approved workspace for human-in-the-loop drafts, active packets, candidate notes, and provisional outputs.
- `approved/`: Tier 1 canonical layer for material the user has explicitly approved for durable reuse.
- `auto/`: Tier 2 autonomous/provisional lane. Useful, but not trusted until reviewed or promoted.
- `memory.md`, `project.md`, and `logs/`: project control plane, not evidence tiers.

## Standard Resume Flow

1. Open `memory.md`.
2. Check `project.md` if you need broader project structure or governance context.
3. Use `approved/index.md` to navigate approved evidence.

## Shared Procedure Rule

Repo-wide procedures should be updated in `workspace/repo/shared-procedures.md` rather than copied into individual projects unless a project needs a local exception.

