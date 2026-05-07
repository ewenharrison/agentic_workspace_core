# Session Initialisation Contract

Use this file to standardize how a new agent session should re-enter the memory system.

## Canonical Initialisation Command

`Initialise project <project-slug>`

Example:

`Initialise project sample-project`

## Personal Context Command

`Initialise personal context`

## Expected Agent Behavior

When the user gives the initialisation command, the agent should:

1. If `profile/context.md` exists, open it first.
2. Open `workspace/repo/shared-procedures.md`.
3. Open task-relevant repo procedures before acting. For literature, web, PubMed, Crossref, Semantic Scholar, journal, or URL access work, open `workspace/repo/literature-search-protocol.md`. For Word export, open `workspace/repo/word-export.md`.
4. Open `workspace/projects/<project-slug>/memory.md`.
5. Open `workspace/projects/<project-slug>/project.md`.
6. Open `workspace/projects/<project-slug>/approved/index.md` for approved evidence navigation. If an older project does not have this file, fall back to `approved/source-index.md`.
7. Open `workspace/projects/<project-slug>/auto/source-index.md` if Tier 2 is enabled or recent exploratory work matters.
8. Check `workspace/projects/<project-slug>/logs/activity.md` for the latest operational changes.
9. Return a short rehydration summary covering:
   - current objective
   - key carried-forward claims
   - open loops
   - next actions
   - any important guardrails
   - which repo-level procedure files were loaded

When the user gives `Initialise personal context`, the agent should:

1. Open `profile/context.md` first.
2. Open the remaining files listed in `profile/init.md`.
3. Return a short rehydration summary covering the most relevant personal-context facts, preferences, active notes, and privacy guardrails.

## Purpose

This command means: "We are starting again. Reload the project context from the memory system before doing new work."

## Notes

- `profile/context.md` is the optional global pre-project briefing file.
- `memory.md` remains the primary quick-start file.
- `project.md` remains the slower-changing governance and structure file.
- `approved/` is canonical. New projects should organise approved material as `approved/framing/`, `approved/sources/`, `approved/syntheses/`, and `approved/outputs/`, with `approved/index.md` as the live navigation file and `approved/source-index.md` retained only as a backward-compatibility redirect.
- `auto/` is provisional unless promoted.
- Repo-level procedures are part of initialisation, not optional background context.
- Prefer British English spelling in repo documentation and memory files where practical.
