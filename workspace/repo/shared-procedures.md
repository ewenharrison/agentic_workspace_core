# Shared Project Procedures

Use this file as the canonical source for repo-wide project procedures.

If a procedure changes, update it here first and then only add project-specific exceptions inside the relevant project folder.

## Procedure Rule

- Shared operational procedures should live in this file or another repo-level procedure file under `workspace/repo/`.
- Projects should link to shared procedures rather than duplicating them where possible.
- Project files should only contain local exceptions, project-specific permissions, or project-specific context.

## Session Re-entry

- If `profile/context.md` exists, load it before project-specific files when re-entering a project.
- Use `Initialise personal context` to load only the personal-context layer.
- Use `Initialise project <project-slug>` to restart a project cleanly in a new session.
- Load this shared-procedures file during project initialisation before acting on project tasks.
- Load task-relevant repo procedure files during initialisation rather than discovering them only after a failure. For literature, web, journal, or URL access work, load [literature-search-protocol.md](literature-search-protocol.md). For Word export, load [word-export.md](word-export.md). For common operational actions, load and use [preflight-checklists.md](preflight-checklists.md).
- Follow the read order defined in [session-init.md](./session-init.md).
- Return a short rehydration summary covering objective, carried-forward claims, open loops, next actions, guardrails, and repo-level procedure files loaded.

## Working Memory Rule

- `profile/context.md` is the primary quick-start file for durable personal context when the `profile/` layer is in use.
- `memory.md` is the primary quick-start briefing for every project.
- `memory.md` is a living project dashboard, not a route for unreviewed agent conclusions to become trusted content. It may record operational state, completed actions, publication status, links, open loops, and pointers to source files or notes. It should not introduce new substantive claims, interpretations, literature conclusions, or recommendations unless they are already supported by Tier 1 approved material or explicitly approved by the user.
- `project.md` is for slower-changing structure, goals, decisions, and governance.
- `working/` is Tier 1 pre-approved space: human-in-the-loop, useful for drafts and provisional notes, but not canonical.
- `approved/` is canonical.
- New projects should organise `approved/` into `framing/`, `sources/`, `syntheses/`, and `outputs/`, with `approved/index.md` as the canonical navigation file.
- Use `approved/framing/` for positioning, rationale, argument structure, concept framing, and other durable scaffolding. Use `approved/outputs/` for completed or agreed deliverables such as final grant applications, manuscripts, submitted cover letters, policy briefs, reviewer packs, and circulation-ready documents.
- Nothing should be written into `approved/` merely because it was found during an initial web or literature search. First-pass search summaries, source notes, and candidate bibliographies belong in `working/` for human review or in `auto/` if generated autonomously.
- New literature or source summaries default to `working/`, even if they are well structured, cited, or written using the source-note template.
- Promote material into `approved/` only after explicit human-in-the-loop approval, or when the user explicitly asks to create an approved note. If a source itself is user-provided or captured for preservation, store the raw file or snapshot in `sources/`; do not treat an agent summary of it as approved until reviewed.
- When the user provides substantive email text, expert feedback, meeting notes, pasted documents, or other primary material, first preserve the raw text in `sources/` before creating a structured summary, synthesis, or project-memory interpretation. The summary should link back to the raw source.
- When a draft or working note is promoted to `approved/`, remove the duplicate copy from `working/` and update links to the approved version, unless the user explicitly asks to preserve a draft history there.
- After any promotion to `approved/`, run a link/path check for the promoted filename or title, update project indexes and memory to the approved path, and verify there is no same-purpose stale copy left in `working/`. This check is mandatory before reporting completion.
- `auto/` is the Tier 2 autonomous lane and is provisional unless promoted. Some projects will have little or no active Tier 2 material.
- Output documents, public copy, manuscripts, grant text, policy notes, and other substantive deliverables should be drafted from Tier 1 approved content by default. Material from `working/`, `auto/`, web search, or model inference can inform suggestions, but it must not be treated as a source for final output unless it has been reviewed and promoted, or the user explicitly authorises its use.

## Tier 2 Rule

- If Tier 2 is enabled proactively, record its permission and limits in `auto/autonomous-lane-policy.md`.
- Tier 2 may support `memory.md` only with clearly bounded operational updates and links to provisional material. Tier 2 must not add unreviewed substantive claims to `memory.md` as if they were project knowledge. Its outputs must remain clearly provisional until reviewed or promoted.

## Preflight Checklist Rule

- Before substantive actions, use the relevant checklist in [preflight-checklists.md](preflight-checklists.md).
- In the working update to the user, briefly name the checklist being used, for example: "Preflight: user-provided source text - raw source first, synthesis second."
- The checklist is not optional when the action involves user-provided primary material, literature/web evidence, promotion to `approved/`, Word export, or commit/push.

## Search, Scout, And Synthesis Rule

- Treat external literature retrieval as a separate search step, not as a default Tier 2 cloud capability.
- Use [literature-search-protocol.md](literature-search-protocol.md) when a task requires PubMed, Crossref, Semantic Scholar, journal, or web searches.
- Store search strategies and executed search results separately in `working/`.
- Store first-pass summaries of search hits in `working/` or `auto/`, not `approved/`, unless the user explicitly approves promotion.
- When triaging sources, compare author lists and acknowledgements with loaded `profile/` identity and project collaborators where relevant. If the user appears to be an author, collaborator, trial lead, consortium lead, or otherwise directly connected, explicitly flag that relationship and adjust interpretation; do not describe the source as merely external background.
- Use `context_scout` only for scanning existing repo context; it must not claim to have run external searches.
- Do not conclude that a public URL is inaccessible from one failed route. Before saying a page cannot be accessed, try at least two materially different access routes where available: browser/web fetch, local `Invoke-WebRequest`, `curl` with redirects, a direct redirected URL if visible, and an unrestricted retry when the failure looks sandbox- or proxy-related.
- Record access failures in search notes with the method used, status code or error, redirect target, date, and whether the failure is a content-level error such as `404` or an environment/client error such as TLS, proxy, connection-close, or sandbox denial.
- If any route succeeds after another route fails, treat the page as accessible and save a local snapshot or source note when the content matters for the project.
- When a real search or `Context Scout` pass finds non-trivial new material, changed framing, or evidence that could alter project positioning, follow it with a `Synthesis Agent` pass.
- Use the `Synthesis Agent` to integrate new findings with existing memory, novelty claims, open loops, and current project framing before deciding what becomes an approved note or a project-memory update.
- Minor confirmatory search results do not always require a synthesis pass.

## Citation Integrity Rule

- For literature reviews, factual briefings, commentary drafts, grant text, policy notes, and other fact-bearing working drafts, include formal citations or source keys against factual claims for the user's review.
- These working citations may later be removed from public-facing final copy when the user asks, but the cited internal version should remain available unless the user asks otherwise.
- Use only citations from confirmed sources: local source files supplied by the user, extracted PDFs, official journal pages, PubMed/Crossref/DOI records, official organisation pages, or executed search-results notes.
- Never generate a bibliographic citation from model memory alone. If a citation has not been confirmed, either verify it first or mark the claim as `[source needed]`.
- If a factual claim cannot be supported by the confirmed source set, do not smooth over the gap. Search, ask, or remove the claim.

## Agent Run Register Rule

- Record cloud and local agent runs in `workspace/runs/agent-runs.md`.
- Include the input file or prompt, output PR or note, status, dependencies, and final decision.
- Do not rely on GitHub PR lists alone as the project-control surface.

## GitHub Actions Preflight Rule

- Before dispatching any GitHub Actions workflow, confirm that every file required by the workflow exists on the remote branch the workflow will run from.
- If the workflow depends on newly created or modified files, commit and push those files before running `gh workflow run` or using the GitHub Actions UI. This includes workflow YAML, scripts, templates, project input files, search protocols, and repo procedure files.
- Do not assume local uncommitted files are visible to GitHub Actions. GitHub Actions runs from the repository state on GitHub, not the local working tree.
- When a workflow fails because a required workflow/script/input was only local, fix the procedure file if needed, commit and push the dependency, then restart the workflow from the pushed commit.

## Pull Sync Rule

- After merging a pull request, pull the latest `main` into the local checkout before continuing work.
- Prefer `git pull --ff-only origin main` when the local branch is `main` and no local divergence is intended.

## Teams Posting Rule

- Collaborator-facing Teams updates should live in `collab/teams-update.md`.
- Default to the adaptive-card webhook workflow supported by `scripts/post-teams-update.ps1`.
- Do not switch to plain text unless there is a clear endpoint-specific reason.

## Slack Posting Rule

- Collaborator-facing Slack updates should live in `collab/slack-update.md`.
- Default to Slack incoming webhooks posted through `scripts/post-slack-update.ps1`.
- If full files need to be posted to Slack, use `scripts/post-slack-file.ps1` so long content is chunked safely across multiple messages.
- Store the Slack webhook URL in `config/slack-webhook-url.txt` or `SLACK_WEBHOOK_URL`.
- If multiple Slack destinations are needed, store them in `config/slack-webhooks.json` and address them by name with `-Target`.
- Prefer incoming webhooks for simple channel updates; use a bot only if you need richer routing, threads, or DMs.
- Treat the webhook as channel-bound unless a richer Slack app setup is introduced later.
- If a Slack post fails inside the sandbox with a connection-level error, an unrestricted retry may still succeed.

## Word Export Rule

- When asked to save, export, render, or convert Markdown to Word, use [word-export.md](word-export.md).
- Default to Pandoc via `scripts/export-markdown-to-word.ps1`.
- Avoid Word COM automation unless the user explicitly asks for it.

## PDF OCR Rule

- When a PDF has no usable text layer, use [pdf-ocr.md](pdf-ocr.md).
- Preferred repo-wide OCR engine: `OCRmyPDF`, backed by Tesseract OCR, producing both a searchable `.ocr.pdf` and a `.ocr.txt` sidecar.
- Avoid Word COM automation for PDF OCR or extraction; it is not a reliable repo-wide path.

## Writing Convention

- Prefer British English spelling in repo documentation and project memory files where practical.
- Use project-specific language only when needed for fidelity.

## Core Promotion Rule

- Treat this private repo as the proving ground for framework ideas.
- Record reusable framework improvements in [core-candidate-changes.md](./core-candidate-changes.md).
- Use [core-promotion.md](./core-promotion.md) as the decision rule for what should move into `agentic_workspace_core`.
- Do not promote real project content, private operational details, or unstable experiments by default.
