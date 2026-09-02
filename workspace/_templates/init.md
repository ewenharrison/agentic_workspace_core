# Initialise `<project-slug>`

Use this file when a new session needs to resume the project cleanly.

## Accepted Command

`Initialise project <project-slug>`

## What That Command Means

The agent should treat the command as a request to reload this project before doing anything else.
Shared procedure details live in [../../repo/shared-procedures.md](../../repo/shared-procedures.md).

## Required Read Order

1. [../../repo/shared-procedures.md](../../repo/shared-procedures.md)
2. [../../repo/preflight-checklists.md](../../repo/preflight-checklists.md) when creating/scaffolding a project or before any substantive action covered by a checklist
3. Task-relevant repo procedure files, such as [../../repo/literature-search-protocol.md](../../repo/literature-search-protocol.md) for external literature, web, journal, or URL access work, [../../repo/signal-review-protocol.md](../../repo/signal-review-protocol.md) for repeated signal review, [../../repo/corpus-retrieval-protocol.md](../../repo/corpus-retrieval-protocol.md) for publication, website, document, dataset, or other corpus retrieval, [../../repo/word-export.md](../../repo/word-export.md) for Word export, or [../../repo/word-track-changes.md](../../repo/word-track-changes.md) for tracked-change Word review
4. [memory.md](./memory.md)
5. [project.md](./project.md)
6. [approved/index.md](./approved/index.md)
7. [auto/index.md](./auto/index.md)
8. [logs/activity.md](./logs/activity.md)

## Project Creation Boundary

When creating a new project, use `scripts/new-project.ps1` and run the `New Project Initiation Or Scaffolding` checklist first. Agent-created notes, syntheses, tasks, and outputs start in `working/`; `approved/` is human-gated and should be locked with `scripts/set-approved-write-lock.ps1`.

## Expected Rehydration Summary

The resume summary should state:

- the current objective
- the key claims being carried forward
- the main open loops
- the next actions
- the current guardrails
- the repo-level procedure files loaded for the task

## Current Resume Intent

Write one sentence describing what future sessions should reload this project as.
