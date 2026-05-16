# Initialise `sample-project`

Use this file when a new session needs to resume the project cleanly.

## Accepted Command

`Initialise project sample-project`

## What That Command Means

The agent should treat the command as a request to reload this project before doing anything else.
Shared procedure details live in [../../repo/shared-procedures.md](../../repo/shared-procedures.md).

## Required Read Order

1. [memory.md](./memory.md)
2. [project.md](./project.md)
3. [approved/index.md](./approved/index.md)
4. [auto/index.md](./auto/index.md)
5. [logs/activity.md](./logs/activity.md)

## Expected Rehydration Summary

The resume summary should state:

- the current objective
- the key claims being carried forward
- the main open loops
- the next actions
- the current guardrails

## Current Resume Intent

Reload this project as the example implementation of the academic agentic memory system.
