# Initialise Personal Context

Use this file when a new session needs to load the durable personal-context layer cleanly.

## Accepted Command

`Initialise personal context`

## What That Command Means

The agent should treat the command as a request to reload the user-level context before doing anything else.
Shared procedure details live in [../memories/repo/shared-procedures.md](../memories/repo/shared-procedures.md).

## Required Read Order

1. [context.md](./context.md)
2. [identity.md](./identity.md)
3. [preferences.md](./preferences.md)
4. [writing_style.md](./writing_style.md)
5. [relationships.md](./relationships.md)
6. [active_notes.md](./active_notes.md)
7. [approved/index.md](./approved/index.md)
8. [auto/index.md](./auto/index.md)
9. [logs/activity.md](./logs/activity.md)

## Expected Rehydration Summary

The resume summary should state:

- the main personal-context facts currently in use
- the writing or collaboration preferences that matter most
- any active personal notes worth carrying into current work
- the main guardrails around private personal context

## Current Resume Intent

Reload this layer as the durable personal context for work across projects, distinct from project-specific memory.
