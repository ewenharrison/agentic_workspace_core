# Word Track Changes Procedure

Use this procedure when the user wants a Word review copy showing changes against a user-edited `.docx`, especially for grant applications, forms, manuscripts, or other documents where formatting and figures matter.

## Execution Boundary

- Treat Word/Office automation as host-bound. Run Word COM actions outside the Codex sandbox with explicit approval.
- Treat tracked-change DOCX package generation as host-bound when the sandbox cannot reliably create or modify temporary DOCX extraction folders.
- Escalation for Word access does not authorise unrelated file moves, imports, external messages, deletion, archiving, or state updates.
- Keep Word hidden unless the user explicitly asks to inspect the document interactively.

## Baseline Rule

- The user-edited Word file is the baseline unless the user explicitly names another file.
- Do not compare against an older Markdown draft, locked submitted draft, or previous agent-generated Word file when the user has given a newer edited Word document.
- If the baseline contains tracked changes, first create an accepted-text baseline copy. Leave the original file untouched.
- If comments are part of the review task, preserve them in a separate source extract or change note before removing them from a comparison copy.

## Recommended Workflow

1. Confirm the exact baseline `.docx` and the intended revised output name.
2. Create an accepted baseline copy outside the sandbox:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\new-word-accepted-copy.ps1 `
  -InputPath "path\to\user-edited-baseline.docx" `
  -OutputPath "workspace\projects\<project>\working\YYYY-MM-DD-<slug>-baseline-accepted.docx" `
  -RemoveComments
```

3. Make the revised clean `.docx` from that baseline. Preserve Word styles, section breaks, headers, tables, figures and captions.
4. If Markdown is used as an editing aid, do not use the Markdown/Pandoc round-trip as the final comparison source unless the user explicitly asks for full regeneration. Word-to-Markdown can alter paragraph structure and may drop embedded figures.
5. Apply any form-specific formatter to the clean revised `.docx` before creating the tracked copy.
6. Generate the tracked-change review copy outside the sandbox:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\new-word-tracked-changes-from-docx.ps1 `
  -BaselinePath "workspace\projects\<project>\working\YYYY-MM-DD-<slug>-baseline-accepted.docx" `
  -RevisedPath "workspace\projects\<project>\working\YYYY-MM-DD-<slug>-clean.docx" `
  -OutputPath "workspace\projects\<project>\working\YYYY-MM-DD-<slug>-tracked-changes.docx" `
  -Author "Review Agent"
```

7. Open the tracked output in Word outside the sandbox as a validation step. Confirm that Word opens the file, that revisions are visible, and that expected figures/media remain embedded.
8. Run a package-level check for the target format: page size, margins, font, header/footer, page breaks, figure count, media count and revision count.
9. Report the baseline file, clean revised file, tracked-change file, and the validation result.

## Script Behaviour And Limits

- `scripts/new-word-tracked-changes-from-docx.ps1` uses direct WordprocessingML revision markup, not native Word Compare.
- It works best when the accepted baseline and revised `.docx` have matching paragraph structure.
- It marks word-level insertions/deletions within changed paragraphs.
- It skips changed paragraphs containing drawings to avoid corrupting images.
- It removes or fixes WordprocessingML compatibility artefacts known to make Word reject generated documents.
- If paragraph counts differ, Word rejects the output, or the revision count is implausible, stop and do not circulate the tracked file.

## Form-Specific Formatter Additions

- Load [word-export.md](word-export.md) as well as this procedure.
- Use the user-edited, formatted `.docx` as the baseline unless the user explicitly names another baseline.
- Apply the relevant checked project-specific formatter to the clean revised `.docx` before producing the tracked copy.
- Before reporting completion, verify page size, margins, fonts, headers/footers, section and page breaks, figures, embedded media, and retained tracked-change markup against the target requirements.

## Known Failure Modes

- Native Word Compare can hang under automation, even outside the sandbox. Prefer the repo tracked-change script unless the user specifically wants an interactive Word Compare.
- A Markdown/Pandoc route can be useful for drafting, but it may drop figures and change paragraph counts. Do not use those normalised Word outputs as the final comparison pair for formatted grant documents.
- Do not hand back a tracked-review document unless Word itself has opened it successfully after generation.
