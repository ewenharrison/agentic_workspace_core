# Preflight Checklists

Use these short checks before common actions. Say the relevant checklist name out loud in the working update when the action is substantive.

## New Project Initiation Or Scaffolding

Use whenever creating a new project folder, project memory files, source notes, draft outputs, or an `approved/index.md`.

- [ ] Load `workspace/repo/shared-procedures.md` and this checklist before creating project files.
- [ ] Use `scripts/new-project.ps1` for project scaffolding instead of manually creating the project files.
- [ ] If `scripts/new-project.ps1` cannot be used, read the relevant templates from `workspace/_templates/`, especially `init.md`, `project_memory.md`, `memory.md`, and `approved_index.md`, before writing files.
- [ ] Preserve raw user-provided files or snapshots in `sources/`; do not treat an agent summary of them as approved.
- [ ] Put all agent-created source notes, syntheses, interview tasks, and draft outputs in `working/` by default.
- [ ] Create only `approved/index.md` as empty or as a navigation file for already-approved material only.
- [ ] Lock the project `approved/` folder with `scripts/set-approved-write-lock.ps1 -Mode Lock -Project <slug>` so direct non-promotion writes fail before landing.
- [ ] In `memory.md` and `project.md`, label draft material as `working/` material, not as approved sources or outputs.
- [ ] Run `scripts/check-approved-boundary.ps1` before reporting completion.
- [ ] If any file is about to enter `approved/`, stop and run the `Promotion To Approved` checklist.

## User-Provided Source Text

Use for pasted emails, expert feedback, meeting notes, copied document text, interview notes, or other primary material supplied by the user.

- [ ] Save the raw text or snapshot in `sources/` before synthesis.
- [ ] Create any structured summary or interpretation in `working/` unless the user explicitly requests approval.
- [ ] Link the summary back to the raw source.
- [ ] Update `memory.md` with both the raw source and working-note links when the material changes project direction.
- [ ] Do not promote the summary to `approved/` unless the user explicitly approves it.

## Local Desktop Or Host-Bound Automation

Use when a workflow depends on local desktop applications, COM objects, GUI sessions, local credentialed clients, or other host-bound resources.

- [ ] Identify whether the command can run in the sandbox or must run outside it.
- [ ] State why the execution boundary exists.
- [ ] State exactly what the escalated or host-bound command is allowed to do.
- [ ] Confirm that access escalation does not relax mutation guardrails.
- [ ] Keep collection, import, state update, send, delete, move, and archive permissions separate.
- [ ] Update workflow state only after the expected output has been written successfully.

## Literature Or Web Search

Use for literature reviews, web searches, source discovery, DOI/PubMed/Crossref checks, and evidence-gathering.

- [ ] Load `workspace/repo/literature-search-protocol.md`.
- [ ] Save the search strategy in `working/`.
- [ ] Save first-pass search results or source notes in `working/` or `auto/`, not `approved/`.
- [ ] Preserve raw PDFs, snapshots, URLs, or source files in `sources/` when they matter for future verification.
- [ ] Use only confirmed citations in fact-bearing drafts.
- [ ] Promote to `approved/` only after explicit user approval.

## Concept Note Or Grant Text Update

Use for edits to grant text, concept notes, circulation drafts, abstracts, summaries, and collaborator-facing copy.

- [ ] Identify the current canonical draft and whether it is `working/` or `approved/`.
- [ ] Preserve user edits; patch rather than regenerate unless asked.
- [ ] Check whether new factual claims need a confirmed source.
- [ ] Keep speculative material in cautious language unless approved evidence supports it.
- [ ] Regenerate Word export if the Markdown draft has a paired `.docx`.
- [ ] Update `memory.md` and activity log when the change alters project direction or circulation state.

## Promotion To Approved

Use whenever moving material from `working/` or `auto/` into `approved/`.

- [ ] Confirm the user explicitly approved promotion or requested an approved note.
- [ ] Use `scripts/promote-to-approved.ps1`; do not use direct shell moves, editor writes, or `apply_patch` to place non-index files in `approved/`.
- [ ] Promote to the correct approved subfolder: `framing/`, `sources/`, `syntheses/`, or `outputs/`.
- [ ] Confirm the same-purpose duplicate was removed from `working/` unless the user asks to preserve it.
- [ ] Update `approved/index.md`, project links and `memory.md`.
- [ ] Run a link/path check for the promoted filename or title.
- [ ] Run `scripts/check-approved-boundary.ps1 -AllowApprovedChanges` only after confirming the user explicitly approved the promotion.

## Word Export

Use when saving, rendering or converting Markdown to Word.

- [ ] Load `workspace/repo/word-export.md`.
- [ ] Use `scripts/export-markdown-to-word.ps1`.
- [ ] Use the project `templates/word-reference.docx` if present; otherwise repo-wide `_templates/word-reference.docx`.
- [ ] Check whether the target funder/journal/form specifies mechanical formatting that overrides the project template.
- [ ] Apply any project-specific post-export formatter required by the target form or submission rules.
- [ ] Overwrite the paired `.docx` when updating an existing exported document.
- [ ] Report if export fails or if Pandoc/reference styles are unavailable.

## Commit And Push

Use when the user asks to commit, push or publish repo state.

- [ ] Run `git status --short`.
- [ ] Mention any unrelated staged/unstaged changes before committing, unless the user explicitly asked for the whole repo.
- [ ] Stage only the intended scope, or the whole repo when explicitly requested.
- [ ] Commit with a message that names the real change.
- [ ] Push to the intended branch.
- [ ] Confirm final status is clean, or state any remaining changes.
