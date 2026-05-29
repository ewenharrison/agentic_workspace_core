# Tier 1 Workflow: Human Reviewed

Use this workflow when new information should not become durable memory until you approve it.

## Default Behavior

- Raw source goes into `sources/`
- Draft note goes into `working/`
- Nothing is treated as canonical until promoted to `approved/`
- Output documents should be created from Tier 1 approved content by default

## Agent Responsibilities

1. Record source metadata.
2. Produce a draft source note.
3. Separate summary from confidence-sensitive claims.
4. Suggest tags, actions, and project links.
5. Propose any updates needed in `memory.md`; substantive claims should only be added once reviewed or explicitly approved.
6. Wait for review before updating approved memory.

When updating `memory.md`, always link source entries to the local note or downloaded file.

## Human Responsibilities

1. Review the draft note.
2. Accept, edit, or reject the proposed summary.
3. Approve any facts that should become durable memory.
4. Decide whether follow-up actions should be added to `memory.md` or `project.md`.

## Promotion Rule

Only reviewed material should move from `working/` into `approved/`.

## Execution Boundary

If a Tier 1 task depends on local desktop applications, COM automation, GUI sessions, local credentialed clients, or other host-bound resources, state the execution boundary before running it. Access escalation for local collection does not relax approval, import, send, move, delete, archive, or state-update guardrails.
