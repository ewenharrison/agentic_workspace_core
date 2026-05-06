# Word Export Routine

Use this routine whenever the user asks to save, export, render, or convert a Markdown file to Word.

## Default Rule

- Use Pandoc, not Word COM automation.
- Use `scripts/export-markdown-to-word.ps1`.
- If no output path is specified, write a `.docx` file next to the source Markdown file with the same base name.
- Overwrite the existing `.docx` export when the user asks to re-render or update the Word version.
- If a project has `templates/word-reference.docx`, the script uses it automatically as the Pandoc reference document for styles/design.
- Otherwise, use the repo-wide default at `workspace/_templates/word-reference.docx` when available.
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

## Pandoc Location

The script first tries to find `pandoc` on `PATH`. On Windows it also checks the standard per-user Pandoc install location under `%LOCALAPPDATA%\Pandoc\pandoc.exe`.

If Pandoc is installed somewhere else, pass the path explicitly:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\export-markdown-to-word.ps1 -InputPath "path\to\file.md" -PandocPath "path\to\pandoc.exe"
```

## Avoid

- Do not use Word COM automation for routine Markdown-to-Word export.
- Do not hand-build `.docx` Open XML packages.
- Do not install another converter unless Pandoc is unavailable or explicitly unsuitable.
