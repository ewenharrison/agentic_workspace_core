# PDF OCR Procedure

Use this file as the repo-wide decision record for OCR on PDFs whose embedded text layer is absent, broken, scanned, or form-encoded.

## Decision

Use `OCRmyPDF` as the preferred repo-wide OCR engine for PDFs.

`OCRmyPDF` should be installed as a command-line tool available to the repo, backed by Tesseract OCR and Ghostscript or equivalent PDF-rendering dependencies. Use it to create a searchable OCR'd PDF and a sidecar text file, then store both beside the source PDF or in the relevant project `inputs/` or `sources/files/` folder.

Do not use Microsoft Word COM automation as the standard PDF extraction path. It is slow, permission-sensitive, difficult to make reproducible, and has already failed in this repo.

## Rationale

- `OCRmyPDF` is purpose-built for scanned and image-only PDFs.
- It preserves the original PDF page image while adding a searchable text layer.
- It can emit a plain-text sidecar file for immediate repo use.
- It is scriptable, batch-friendly, and auditable.
- It uses Tesseract, the mature open OCR engine, but avoids making every repo task manage page rendering and OCR calls manually.
- It is better as a repo standard than ad hoc Python OCR because it handles normal PDF OCR concerns such as rotation, deskewing, image optimisation, and text-layer insertion.

## Recommended Installation Shape

Preferred Windows route:

1. Install 64-bit Tesseract OCR.
2. Install 64-bit Ghostscript or the current OCRmyPDF-supported rendering dependency path.
3. Install `ocrmypdf` into the Python environment used by repo scripts.
4. Confirm from PowerShell:

```powershell
ocrmypdf --version
tesseract --version
gswin64c --version
```

If native Windows installation is awkward, use WSL or Docker for `ocrmypdf`, but expose a single repo command so project workflows do not care which backend is used.

## Standard Repo Invocation

Target behaviour for a future wrapper script:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\ocr-pdf.ps1 -InputPath "<input.pdf>"
```

Expected outputs:

- `<input>.ocr.pdf`: searchable PDF with OCR text layer.
- `<input>.ocr.txt`: plain-text sidecar extraction.
- `<input>.ocr-log.md`: short audit note with command, date, exit status, OCR engine, and any warnings.

Recommended `ocrmypdf` options for English-language academic/admin PDFs:

```powershell
ocrmypdf --skip-text --rotate-pages --deskew --sidecar "<input>.ocr.txt" "<input.pdf>" "<input>.ocr.pdf"
```

Use `--force-ocr` only when the existing text layer is present but unusably corrupt. Record that choice in the OCR log because it replaces rather than preserves the existing text layer.

## Storage Convention

- Keep the original PDF.
- Put OCR outputs in the same candidate/manuscript/source folder as the original unless a project has a more specific convention.
- Treat OCR text as a working aid, not the primary source. The source PDF remains canonical.
- If OCR quality is poor, note the limitation in the relevant project packet.

## Fallbacks

- For digitally generated PDFs with a good text layer, use `pypdf` or another direct text extractor first. OCR is unnecessary and may introduce errors.
- If `OCRmyPDF` is unavailable but `PyMuPDF` OCR support is installed, it can be used as a fallback, but this is not the preferred repo-wide standard.
- If neither OCR path is available, record the failure and request either OCR installation or a text-exported copy of the PDF.

## Current Trigger Case

This decision was prompted by `lister_institute/interviews`, application `1664`, where the full review PDFs copied successfully but local `pypdf` extraction returned only form artifacts such as `/0`, `/1`, and `/2`, and Word COM conversion hung.

## Local Environment Note

On 2026-05-11, the first Windows installation used:

- Tesseract OCR 5.4.0 via `winget install -e --id UB-Mannheim.TesseractOCR`
- Ghostscript 10.07.0 from the official Artifex GitHub release asset
- OCRmyPDF 17.4.2 via `python -m pip install ocrmypdf`

Inside the Codex sandbox, OCRmyPDF failed while creating temporary working files. Running `python -m ocrmypdf` outside the sandbox succeeded. Future wrapper scripts should either request unrestricted execution for OCR or set and verify a writable temp directory before calling OCRmyPDF.
