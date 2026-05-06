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
- `workspace/projects/<project-slug>/approved/source-index.md` as a backward-compatibility redirect
- `workspace/projects/<project-slug>/approved/framing/`
- `workspace/projects/<project-slug>/approved/sources/`
- `workspace/projects/<project-slug>/approved/syntheses/`
- `workspace/projects/<project-slug>/auto/source-index.md`
- `workspace/projects/<project-slug>/auto/autonomous-lane-policy.md` when Tier 2 is enabled proactively
- `workspace/projects/<project-slug>/logs/activity.md`
- `workspace/projects/<project-slug>/collab/teams-update.md` when Teams sharing is used
- `workspace/projects/<project-slug>/sources/files/`
- `workspace/projects/<project-slug>/sources/links/`
- `workspace/projects/<project-slug>/working/`

## Standard Resume Flow

1. Open `memory.md`.
2. Check `project.md` if you need broader project structure or governance context.
3. Use `approved/index.md` to navigate approved evidence, with `approved/source-index.md` only as a fallback for older projects.

## Shared Procedure Rule

Repo-wide procedures should be updated in `workspace/repo/shared-procedures.md` rather than copied into individual projects unless a project needs a local exception.

