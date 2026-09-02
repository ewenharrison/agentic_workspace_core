# Core Candidate Changes

Use this file as the running shortlist of framework improvements that may be promoted to `agentic_workspace_core`.

## Status Key

- `Active candidate`: not yet promoted to the public core repo
- `Promoted`: already copied into `agentic_workspace_core`
- `Watch`: promising, but should prove itself further
- `Keep private`: useful locally, but not suitable for core

## Active Candidates

No active candidates after the 2026-09-02 promotion review.

When adding a candidate, include:

- date and short title
- status
- why it matters
- evidence from live use
- whether it is generic enough for public core
- exact files or conventions that would need promotion

## Watch

### Collaborator updates stored at `collab/`
- Status: `Watch`
- Why: the location is sensible, but the Teams-specific wording may later broaden into a more general collaborator update pattern.
- Evidence: useful in practice, but not yet proven outside the current setup.

### GitHub helper script
- Status: `Watch`
- Why: useful operationally, but may need cleanup and clearer scope before inclusion in a public core repo.
- Evidence: could be useful, but should mature before promotion.

### Tier 2 LLM-as-judge relevance control
- Status: `Watch`
- Why: potentially useful for literature-heavy projects, but not yet implemented or designed enough for a core feature.
- Evidence: captured as a future requirement in the Tier 2 workflow.

### Platform-specific signal collectors
- Status: `Watch`
- Why: the generic signal-review lifecycle has been promoted, but individual collectors still depend on local platforms, credentials, schedules, and destination details.
- Evidence: live use showed the workflow is valuable, but public promotion should stay connector-agnostic unless a specific public connector is deliberately supported.

### Project reminder action surface
- Status: `Watch`
- Why: the daily/weekly project-reminder loop is valuable, but the current implementation is Trello-specific and deliberately exports private project names and next-action text to a configured external board.
- Evidence: live use across many projects shows a strong reusable pattern: scan `memory.md` next actions, distinguish recent/dirty project activity from all-project review, support ignore and snooze rules, and rebuild the external checklist atomically.
- Possible core-safe direction: promote later as a connector-agnostic reminder protocol plus optional sink adapters, with generic example config and explicit external-transfer guardrails.

## Keep Private

### Personal headed-letter assets and signing workflow
- Status: `Keep private`
- Why: personal letterhead, professional contact blocks, local profile paths and ink signatures are user-specific. An ink signature is a signing credential and must not enter the public core export.
- Evidence: a user-finalised promotion letter showed that a reference document preserves headers but silently drops body signatures and may lose visible paragraph separation. The private profile workflow now uses a sanitized header reference, explicit body spacing and an opt-in signing wrapper.
- Core-safe lesson: retain only the generic procedure that profile-specific formal correspondence must be selected explicitly, signatures require per-document authority and paragraph spacing must be validated.

### Adaptive-card Teams webhook default
- Status: `Keep private`
- Why: this is an environment-specific operational detail rather than a universal framework default.
- Evidence: valuable here, but too implementation-specific for the core repo unless the public repo is explicitly Teams-oriented.

### Reviewer-pack workflow
- Status: `Keep private`
- Why: this is specific to a local editorial workflow.
- Evidence: a local reviewer-pack project has a useful repeatable structure, but the public core should not carry that editorial pattern as a generic default.

### Local icon or asset library indexes
- Status: `Keep private`
- Why: local icon, image, and asset-library indexes are environment-specific and may include absolute paths, licence-sensitive metadata, or paid asset references.
- Evidence: useful locally, but explicitly out of scope for public core promotion.
- Rule: never promote the local icon or asset library process, indexes, search scripts, or metadata into `agentic_workspace_core`.

## Promoted

### 2026-09-02: PubMed `efetch` batching hardening
- Status: `Promoted`
- Why: protocol-driven PubMed searches should handle larger result sets without failing on a single oversized `efetch` request.
- Promoted files/conventions: `scripts/run-pubmed-literature-search.ps1` now fetches records in bounded chunks with a short inter-request pause and derives fallback titles from the protocol filename safely.

### 2026-09-02: source-sidecar extract convention
- Status: `Promoted`
- Why: durable, exact machine-readable extracts should live beside preserved source material rather than as durable clutter in `working/`.
- Promoted files/conventions: shared procedures and preflight checklists now place PDF, DOCX, slide, webpage, and OCR extracts in `sources/files/` or `sources/files/extracted-text/`, while reserving `working/` for notes, manifests, syntheses, and provisional outputs.

### 2026-09-02: constraint-aware independent review protocol
- Status: `Promoted`
- Why: grant, manuscript, programme, and competitive-submission reviews need a clean-room method that distinguishes correctable defects from strategic trade-offs.
- Promoted files/conventions: `workspace/repo/independent-review-protocol.md`, shared procedures, preflight checklists, session initiation, and agent prompt snippets.

### 2026-09-02: Word export and tracked-change review hardening
- Status: `Promoted`
- Why: Word workflows need to preserve manually formatted baselines, distinguish accepted and marked-up states, produce auditable tracked review copies, and avoid heading-spacing failures in routine exports.
- Promoted files/conventions: generic Word export and tracked-change procedures; accepted-copy, tracked-change, comment, paragraph, revision, and proofing inspection helpers; heading-style hardening in `scripts/export-markdown-to-word.ps1`; and task-loading/preflight guidance.

### 2026-09-02: generated scaffold Markdown escaping fix
- Status: `Promoted`
- Why: generated project Markdown must preserve literal code paths and checklist tokens inside PowerShell here-strings.
- Promoted files/conventions: `scripts/new-project.ps1` now escapes Markdown backticks in generated project files and activity text.

### 2026-09-02: local scheduled-workflow wake/network guardrail
- Status: `Promoted`
- Why: scheduled local workflows must tolerate sleeping devices and brief post-wake network delays without overlapping runs or advancing completed state after failure.
- Promoted files/conventions: connector-agnostic guidance in `workspace/repo/shared-procedures.md`; platform-specific collectors remain private.

### 2026-06-13: mandatory date-prefixed `working/` filenames
- Status: `Promoted`
- Why: dated working filenames make project chronology, duplicate detection, and later promotion review much easier.
- Promoted files/conventions: shared procedures, preflight checklists, literature-search protocol, README, and agent prompt snippets now require non-placeholder files created in `working/` to begin with `YYYY-MM-DD-`.

### 2026-06-13: generic signal-review lifecycle
- Status: `Promoted`
- Why: repeated review of incoming streams needs a reusable safety pattern: bounded read-only collection, temporary packet, digest, validation, state update only after success, and project handoff prompts.
- Promoted files/conventions: `workspace/repo/signal-review-protocol.md`, `workspace/_templates/signal_review_digest.md`, shared procedures, preflight checklists, session-init, README, and agent prompt snippets.

### 2026-06-13: generic corpus retrieval protocol
- Status: `Promoted`
- Why: multi-item retrieval from external sources needs explicit access smoke tests, credential boundaries, manifests, checksums, conservative batching, and extraction status before synthesis.
- Promoted files/conventions: `workspace/repo/corpus-retrieval-protocol.md`, `workspace/_templates/corpus_retrieval_plan.md`, shared procedures, preflight checklists, session-init, README, and literature-search protocol cross-links.

### 2026-06-13: publication corpus review schema
- Status: `Promoted`
- Why: article-level or publication-level reviews benefit from a reusable schema covering publication identity, source/access status, review classification, methods/evidence, technology or intervention fields, equity/safety/governance, and coding uncertainty.
- Promoted files/conventions: `workspace/_templates/publication_corpus_review_schema.md` and the corpus retrieval protocol's schema handoff rule.

### 2026-05-29: explicit execution-boundary rules for local desktop automation
- Status: `Promoted`
- Why: Workflows may depend on local desktop applications, COM objects, GUI sessions, local credentialed clients, or other host-bound resources. These can fail inside the Codex sandbox even when the same read-only command succeeds with local host execution.
- Promoted files/conventions: generic execution-boundary rule in shared procedures, preflight checklist coverage for host-bound automation, and execution-boundary sections in Tier 1 and Tier 2 workflow docs.

### 2026-05-29: harden new-project approval boundary
- Status: `Promoted`
- Why: Project initiation needs a stronger guardrail so scaffolding does not place agent-authored notes, source summaries, syntheses, tasks, or outputs into `approved/` before human review.
- Promoted files/conventions: `scripts/new-project.ps1`, `scripts/set-approved-write-lock.ps1`, `scripts/promote-to-approved.ps1`, `scripts/check-approved-boundary.ps1`, shared procedures, session-init, project templates, and `workspace/repo/agent-prompt-snippets.md`.

### 2026-05-29: Word export attributes and submission-specific formatting rule
- Status: `Promoted`
- Why: Pandoc exports sometimes need Markdown attributes, and final submission documents may need mechanical formatting that overrides the repo or project reference document.
- Promoted files/conventions: `scripts/export-markdown-to-word.ps1` now uses `gfm+attributes`; Word export procedures and preflight checklist require checking target submission formatting and using a project-specific checked formatter when needed.

### 2026-05-16: preflight checklists for common repo actions
- Status: `Promoted`
- Why: recurring agent failures came from remembering procedures as prose rather than running operational checks at the point of action.
- Evidence: the Cathie Sudlow feedback email was initially summarised without first preserving the raw email source, despite the repo's raw-source rule.
- Promoted files/conventions: `workspace/repo/preflight-checklists.md`; shared-procedure rule requiring relevant checklist use before substantive actions.

### 2026-05-16: retire `source-index.md` compatibility redirects
- Status: `Promoted`
- Why: `approved/index.md` is now the canonical approved navigation file, and retaining `approved/source-index.md` as a backward-compatibility redirect creates duplicate-looking navigation surfaces.
- Evidence: repo guidance, templates, project quick links, and session initialisation already preferred `approved/index.md`; the duplicate filenames caused confusion when scanning project folders.
- Promoted files/conventions: new projects use `approved/index.md`, `auto/index.md`, and local `sources/.../index.md` files rather than `source-index.md`; Tier 2 runner now updates `auto/index.md`.

### 2026-05-16: repo-wide PDF OCR procedure
- Status: `Promoted`
- Why: scanned or malformed PDFs are common in academic/admin workflows; OCR needs a reproducible path that does not depend on Microsoft Word automation.
- Evidence: `lister_institute/interviews` application `1664` review PDFs had unusable embedded text; local `pypdf` extraction returned only form artifacts and Word COM conversion hung.
- Promoted files/conventions: `workspace/repo/pdf-ocr.md`; shared-procedure OCR rule recommending OCRmyPDF with Tesseract. This is documentation only until an OCR wrapper script is added.

### 2026-05-09: explicit workspace structure map and tier-folder legend
- Status: `Promoted`
- Why: first-time readers can miss that `working/` is still Tier 1 and that `approved/` is a reviewed subset of Tier 1, while `auto/` is the separate Tier 2 lane.
- Evidence: presentation preparation surfaced ambiguity in folder naming and limited current use of `auto/`.
- Promoted files/conventions: `STRUCTURE.md`, README short link, registry legend, shared-procedure wording.

### 2026-05-07: `memory.md` dashboard boundary and Tier 1 output rule
- Status: `Promoted`
- Why: `memory.md` is useful as a living project dashboard, but it must not become a route for unreviewed agent conclusions to enter trusted project memory.
- Evidence: live project work around a published Conversation article exposed the need to distinguish operational memory updates from substantive claims.
- Promoted files/conventions: shared procedures, Tier 1 and Tier 2 workflows, memory template, and project guardrails.

### 2026-05-07: approved outputs folder convention
- Status: `Promoted`
- Why: `framing/` is for project positioning and argument scaffolding, not every completed deliverable.
- Evidence: live projects needed a first-class approved home for final grants, manuscripts, cover letters, policy briefs, reviewer packs, and circulation-ready documents.
- Promoted files/conventions: `approved/outputs/`, README, templates, registry guidance, session initialisation, shared procedures, and sample project.

### 2026-05-07: PubMed literature search workflow
- Status: `Promoted`
- Why: real literature retrieval needs explicit search execution, search-result files, and source counts rather than prompt-only cloud synthesis.
- Evidence: `scripts/run-pubmed-literature-search.ps1`, `.github/workflows/pubmed-literature-search.yml`, and `workspace/_templates/pubmed_search_protocol.md` support protocol-driven PubMed retrieval, working search-results notes, PR return, and optional Synthesis Agent handoff.
- Promoted files/conventions: PubMed workflow YAML, runner script, protocol template, and literature-search procedure updates.

### 2026-05-07: GitHub Actions preflight rule
- Status: `Promoted`
- Why: cloud agents fail in confusing ways when workflow YAML, runner scripts, templates, or project input files exist only in the local working tree.
- Evidence: live GitHub Actions work exposed that the cloud runner only sees committed and pushed repository state.
- Promoted files/conventions: shared procedures, Tier 2 workflow, and literature-search protocol.

### Earlier Promoted Framework Features
- Status: `Promoted`
- Includes: standard `init.md`; `memory.md` as the first-stop briefing; central `workspace/repo/shared-procedures.md`; explicit `auto/autonomous-lane-policy.md`; top-level `profile/`; `working/` as Tier 1 pre-approved workspace; Context Scout and Synthesis Agent modes; separate literature-search protocol; cross-project agent run register; Markdown-to-Word export routine; multi-route web access failure checks; repo procedures loaded during project initialisation; stricter approval boundary for search-derived summaries; source triage for user authorship and collaborator connection; citation integrity for fact-bearing drafts.
