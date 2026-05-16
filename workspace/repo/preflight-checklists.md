# Preflight Checklists

Use these short checks before common actions. Say the relevant checklist name out loud in the working update when the action is substantive.

## User-Provided Source Text

Use for pasted emails, expert feedback, meeting notes, copied document text, interview notes, or other primary material supplied by the user.

- [ ] Save the raw text or snapshot in `sources/` before synthesis.
- [ ] Create any structured summary or interpretation in `working/` unless the user explicitly requests approval.
- [ ] Link the summary back to the raw source.
- [ ] Update `memory.md` with both the raw source and working-note links when the material changes project direction.
- [ ] Do not promote the summary to `approved/` unless the user explicitly approves it.

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
- [ ] Move the file to the correct approved subfolder: `framing/`, `sources/`, `syntheses/`, or `outputs/`.
- [ ] Remove the same-purpose duplicate from `working/` unless the user asks to preserve it.
- [ ] Update `approved/index.md`, project links and `memory.md`.
- [ ] Run a link/path check for the promoted filename or title.

## Word Export

Use when saving, rendering or converting Markdown to Word.

- [ ] Load `workspace/repo/word-export.md`.
- [ ] Use `scripts/export-markdown-to-word.ps1`.
- [ ] Use the project `templates/word-reference.docx` if present; otherwise repo-wide `_templates/word-reference.docx`.
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
