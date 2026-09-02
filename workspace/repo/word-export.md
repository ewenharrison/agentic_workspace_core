# Word Export Routine

Use this routine whenever the user asks to save, export, render, or convert a Markdown file to Word.

## Default Rule

- Use Pandoc, not Word COM automation.
- Use `scripts/export-markdown-to-word.ps1`.
- If no output path is specified, write a `.docx` file next to the source Markdown file with the same base name.
- Overwrite the existing `.docx` export when the user asks to re-render or update the Word version.
- If a project has `templates/word-reference.docx`, the script uses it automatically as the Pandoc reference document for styles/design.
- Otherwise, use the repo-wide default at `workspace/_templates/word-reference.docx` when available.
- Use `-UsePandocDefaultReference` for standalone notes and review reports when the nearest project template is designed for a compressed grant, form, or other submission-specific document.
- For ordinary documents, the export script adds 6 pt after heading styles when the selected reference document specifies no space. This prevents paragraph text or lists from running into headings.
- Pass `-PreserveReferenceHeadingSpacing` only when the reference document's zero heading spacing is intentional. A submission-specific formatter may also reset heading spacing after export.
- The script renders to a temporary file first. If the existing `.docx` is locked by Word, preview, or sync, it saves a timestamped fallback `.docx` next to the source file instead of failing.

## Command

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\export-markdown-to-word.ps1 -InputPath "workspace\projects\<project-slug>\working\<note>.md"
```

To specify a different output path:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\export-markdown-to-word.ps1 -InputPath "path\to\file.md" -OutputPath "path\to\file.docx"
```

To specify a different Word reference document:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\export-markdown-to-word.ps1 -InputPath "path\to\file.md" -ReferenceDocPath "path\to\word-reference.docx"
```

To use Pandoc's standard Word reference instead of a project template:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\export-markdown-to-word.ps1 -InputPath "path\to\file.md" -UsePandocDefaultReference
```

## Pandoc Location

The script first tries to find `pandoc` on `PATH`. On Windows it also checks the standard per-user Pandoc install location under `%LOCALAPPDATA%\Pandoc\pandoc.exe`.

If Pandoc is installed somewhere else, pass the path explicitly:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\export-markdown-to-word.ps1 -InputPath "path\to\file.md" -PandocPath "path\to\pandoc.exe"
```

## Submission-Specific Formatting

- If a funder, journal, university form or application guidance specifies mechanical formatting, check those rules after export. A project `word-reference.docx` may be visually attractive but still wrong for the form.
- Apply the specified page size, margins, font, font size, line spacing, headers/footers and page-numbering rules before reporting completion.
- If a project has a checked formatter for a specific form or submission route, export from Markdown first and then run that formatter, for example:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\<project-specific-formatter>.ps1 -InputPath "workspace\projects\<project-slug>\working\<note>.docx"
```

## Profile-Specific Formal Correspondence

- When the live `profile/` layer provides a formal-correspondence template and workflow, use it explicitly for headed letters rather than making personal letterhead the generic Word default.
- A Pandoc reference document can preserve headers, page geometry and styles, but it does not carry a signature drawing or signatory block from the reference body. Use the profile's checked wrapper or formatter for those elements.
- Treat an ink signature as a signing credential. Insert it only with explicit per-document authority, never during routine draft generation or autonomous runs.
- Letter-specific styles must provide visible body-paragraph spacing; do not rely on manual empty paragraphs surviving a Markdown-to-Word round trip.
- Keep address and signatory lines compact, normally through line breaks or a compact paragraph style.
- Prefer distributing signed correspondence as PDF rather than DOCX, unless the editable Word file is specifically required.

## Formatted Grant Documents And Track Changes

- Once a grant/application Word document has been manually formatted or has form-specific formatting applied, do **not** use a Markdown/Pandoc round-trip as the final reviewed `.docx` unless the user explicitly asks for a full regeneration.
- For tracked-change review of an already edited Word document, load and follow [word-track-changes.md](word-track-changes.md).
- For tracked-change review against a user-edited Word file, treat the user-edited `.docx` as the baseline. Create a new revised `.docx` from that baseline, preserving Word styles, page setup, section breaks, headers, tables, figures and captions.
- If the user-edited Word baseline contains tracked changes or comments, first work from its accepted text as the baseline state. Do not mix accepted baseline text with older Markdown wording or prior outline drafts.
- Use `scripts/new-word-accepted-copy.ps1` to create the accepted baseline copy, and run it outside the sandbox because it automates Word.
- Before handing back a tracked-changes grant file, perform a no-op baseline test: baseline-to-copy comparison should produce zero substantive changes. Then apply only explicitly approved replacements anchored to exact baseline wording.
- Every changed paragraph in a tracked-changes grant file must have a reason in a short change table. If a paragraph differs only because a Markdown reconstruction changed wording, the output has failed and must not be circulated.
- If a Markdown route is used only to draft text, the final Word output must still be passed through the relevant form-specific formatter and verified before reporting completion.
- Use `scripts/new-word-tracked-changes-from-docx.ps1` to create the tracked-review `.docx` when native Word Compare is unavailable or hangs. Treat package generation as host-bound when the sandbox cannot create or modify the temporary DOCX extraction tree.
- Validate any tracked-review `.docx` by opening it in Word outside the sandbox and checking that Word reports visible revisions. Do not circulate a tracked file that has not passed this open test.
- When a target route has a checked project-specific formatter, run it with the required non-secret parameters before creating the tracked copy or reporting completion.
- Verify the formatter's output against the target requirements, including page geometry, typography, headers/footers, required page breaks, figures, and embedded media. Preserve the verification result in the working update or final summary.
- If formatting is applied to a tracked-change file, verify afterwards that revision markup still exists in `word/document.xml` and that expected media files remain embedded.

## Avoid

- Do not use Word COM automation for routine Markdown-to-Word export.
- Do not hand-build `.docx` Open XML packages outside a checked, documented formatter script for a specific form requirement.
- Do not use a Markdown-normalised `.docx` as the final comparison source for a manually formatted grant document unless the user explicitly asks for that trade-off.
- Do not install another converter unless Pandoc is unavailable or explicitly unsuitable.
- Do not hand back a form-constrained Word draft after a raw Pandoc export without applying and verifying the required target-specific formatting.
