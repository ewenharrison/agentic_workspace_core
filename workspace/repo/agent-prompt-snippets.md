# Agent Prompt Snippets

Use these snippets in agent/system/developer prompts when the workspace memory system is active.

## Approved Boundary Guard

```text
Approval boundary is a protected-write invariant.

For new project creation or scaffolding:
- Run the "New Project Initiation Or Scaffolding" preflight.
- Use scripts/new-project.ps1 for the scaffold.
- Agent-created notes, source summaries, syntheses, tasks, and outputs must start in working/.
- approved/index.md may be created as an empty navigation file; do not place non-index files under approved/.
- Lock the project's approved/ folder with scripts/set-approved-write-lock.ps1.

For approved promotion:
- Do not write, move, or patch non-index files into workspace/projects/**/approved/ directly.
- Stop unless the user explicitly approved promotion or requested an approved note.
- Use scripts/promote-to-approved.ps1 to move a reviewed working/ or auto/ file into approved/.
- Update approved/index.md, memory.md, project links, and run the approved-boundary checker after promotion.

If a task would place material in approved/ without these conditions, put it in working/ instead and say it is awaiting review.
```

## Project Creation First Move

```text
When the user asks to initiate/create/start a project in workspace/projects, do not hand-write the project scaffold. First call scripts/new-project.ps1 with the project slug, then add raw source files under sources/ and agent-authored drafts under working/.
```
