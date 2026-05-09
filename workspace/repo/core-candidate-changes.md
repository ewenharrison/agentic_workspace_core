# Core Candidate Changes

Use this file as the running shortlist of framework improvements that may be promoted to `agentic_workspace_core`.

## Status Key

- `Promote now`: mature and reusable
- `Watch`: promising, but should prove itself further
- `Keep private`: useful locally, but not suitable for core

## Current Candidates

### 2026-05-09: explicit workspace structure map and tier-folder legend
- Status: `Promote now`
- Why: first-time readers can miss that `working/` is still Tier 1 and that `approved/` is a reviewed subset of Tier 1, while `auto/` is the separate Tier 2 lane.
- Evidence: presentation preparation surfaced ambiguity in the folder naming and the limited current use of `auto/`; the repo now has a top-level `STRUCTURE.md`, README short version, registry legend, and shared-procedure wording.
- Scope: documentation and export only. Keep the existing folder names rather than renaming to `tier1_working`, `tier1_approved`, and `tier2_auto`, because the shorter names are easier to use once the structure map is explicit.

### 2026-05-01: approved index folder convention
- Status: `Promote now`
- Why: approved material becomes hard to navigate when internal framing, source notes, and syntheses sit together in one flat folder.
- Evidence: multiple live projects proved the pattern with `approved/framing/`, `approved/sources/`, `approved/syntheses/`, and `approved/index.md`; repo templates, session initialisation, shared procedures, README guidance, and the Tier 2 runner now prefer `approved/index.md` while retaining `approved/source-index.md` as a backward-compatibility redirect.
- Scope: applies to new projects and projects explicitly migrated later; existing older projects can remain unchanged until there is a reason to reorganise them.

### 2026-04-15: `init.md` as a standard project bootstrap
- Status: `Promote now`
- Why: this improves project rehydration for any project and is already reusable.
- Evidence: used successfully across multiple projects.

### 2026-04-15: `memory.md` as the default first-stop briefing file
- Status: `Promote now`
- Why: the split between fast briefing and slower project governance is one of the strongest framework decisions so far.
- Evidence: now embedded consistently across the repo structure.

### 2026-04-15: shared repo procedures centralised in `workspace/repo/shared-procedures.md`
- Status: `Promote now`
- Why: this reduces duplication and makes framework evolution easier.
- Evidence: already supports multiple projects cleanly.

### 2026-04-15: explicit `auto/autonomous-lane-policy.md` for proactive Tier 2 use
- Status: `Promote now`
- Why: it creates a clear boundary around autonomous behaviour and permissions.
- Evidence: reusable across any project that enables Tier 2.

### 2026-04-15: collaborator updates stored at `collab/teams-update.md`
- Status: `Watch`
- Why: the location is sensible, but the Teams-specific wording may later broaden into a more general collaborator update pattern.
- Evidence: useful in practice, but not yet proven outside the current setup.

### 2026-04-15: adaptive-card Teams webhook default
- Status: `Keep private`
- Why: this is an environment-specific operational detail rather than a universal framework default.
- Evidence: valuable here, but too implementation-specific for the core repo unless the public repo is explicitly Teams-oriented.

### 2026-04-15: GitHub helper script
- Status: `Watch`
- Why: useful operationally, but may need cleanup and clearer scope before inclusion in a public core repo.
- Evidence: could be useful, but should mature before promotion.

### 2026-04-16: top-level `profile/` layer for personal context
- Status: `Promote now`
- Why: the separation between user-level context and project memory is now considered a core-worthy framework feature rather than a local experiment.
- Evidence: implemented with explicit session-init rules, privacy guardrails, and reusable command/documentation support across the live repo.

### 2026-04-22: use `working/` as the Tier 1 pre-approved workspace
- Status: `Promote now`
- Why: `working/` better captures the actual role of pre-approved drafts, concept notes, search strategies, figures, and structured notes, while `sources/` remains the raw intake layer.
- Evidence: migrated across all live project folders and repo-level docs.

### 2026-04-22: Context Scout and Synthesis Agent modes
- Status: `Promote now`
- Why: reusable agent roles make Tier 2 more explicit while avoiding overclaiming that repo-context scanning is external literature search.
- Evidence: prompt templates exist and `run-tier2-cloud-task.ps1` can resolve `general`, `context_scout`, and `synthesis_agent` modes.
- Evidence: the core manual workflow now exposes `agent_mode`.

### 2026-04-22: separate literature-search protocol from cloud agent modes
- Status: `Promote now`
- Why: real literature retrieval needs explicit search execution, search-result files, and source counts rather than prompt-only cloud synthesis.
- Evidence: the project exposed a failure mode where a PubMed search strategy was sent to a context-only agent mode.

### 2026-04-22: cross-project agent run register
- Status: `Promote now`
- Why: multi-agent PR workflows need a readable project-control surface beyond GitHub's PR list.
- Evidence: scheduled sample-project PRs and healthcare scout/synthesis handoffs became hard to track without an explicit register.

### 2026-04-22: Markdown-to-Word export routine
- Status: `Promote now`
- Why: a Pandoc-backed Word export rule is reusable for concept notes and collaborator-facing drafts.
- Evidence: the script and documentation are generic enough for core export.

### 2026-04-22: Tier 2 LLM-as-judge relevance control
- Status: `Watch`
- Why: potentially useful for literature-heavy projects, but not yet implemented or designed enough for a core feature.
- Evidence: captured as a future requirement in the Tier 2 workflow.

### 2026-04-28: multi-route web access failure checks
- Status: `Promote now`
- Why: single-route web failures can be false negatives because sandbox proxying, redirects, TLS handling, user-agent handling, or institutional hosting layers can differ by client.
- Evidence: live project work exposed a false inaccessible-page conclusion that was resolved by trying a different client and following the redirect chain.

### 2026-04-28: repo procedures loaded during project initialisation
- Status: `Promote now`
- Why: repo-wide procedures are only protective if they are loaded before task execution; relying on ad hoc discovery after something goes wrong leaves predictable gaps.
- Evidence: live project work exposed an initialisation gap where an existing repo procedure was not consulted before task execution.

### 2026-04-28: stricter approval boundary for search-derived summaries
- Status: `Promote now`
- Why: `approved/` should mean human-reviewed canonical memory. Initial web-search summaries can be useful and well formed but should not acquire approved status without explicit human-in-the-loop promotion.
- Evidence: live project setup revealed that candidate literature found during initialisation could be placed into an approved source index before review. This is now covered in shared procedures, the literature-search protocol, the source-note template, and the synthesis-agent prompt.

### 2026-04-28: source triage checks user authorship and collaborator connection
- Status: `Promote now`
- Why: sources authored by the user or close collaborators should be interpreted differently from generic external background, especially when they establish prior field position or continuity.
- Evidence: live literature triage initially framed directly connected prior work as generic external background; the source-connection check corrects that failure mode.

### 2026-04-30: repo-wide email and note-capture procedures
- Status: `Watch`
- Why: email handling and note capture are useful across projects, but the implementation depends on session-level connector availability and private destination details.
- Evidence: live use showed the workflow is valuable, but public promotion needs a connector-agnostic and destination-free version.

### 2026-05-01: citation integrity for fact-bearing drafts
- Status: `Promote now`
- Why: literature reviews, commentary drafts, grants, and policy notes need internal citation keys against factual claims to prevent unsupported assertions and hallucinated references.
- Evidence: live drafting workflows required cited working drafts and confirmed source maps; the rule is now recorded in shared procedures and the literature-search protocol.

### 2026-05-07: PubMed literature search workflow
- Status: `Promote now`
- Why: this is the first source-specific cloud literature retrieval workflow and fixes the earlier failure mode where a prompt-only agent treated a search strategy as if it had executed a search.
- Evidence: `scripts/run-pubmed-literature-search.ps1`, `.github/workflows/pubmed-literature-search.yml`, and `workspace/_templates/pubmed_search_protocol.md` now support protocol-driven PubMed retrieval, working search-results notes, PR return, and optional Synthesis Agent handoff. The `roboscot` project has a PubMed protocol/results pattern that demonstrates the intended handoff shape.
- Promotion note: the core export includes the PubMed template, procedure updates, workflow YAML, and runner script, so this is promotable as a runnable first-pass literature-search agent.
- Scope: PubMed only for the first implementation. Broader source support should be added source by source after this has run successfully.

### 2026-05-07: GitHub Actions preflight rule
- Status: `Promote now`
- Why: cloud agents fail in confusing ways when workflow YAML, runner scripts, templates, or project input files exist only in the local working tree.
- Evidence: live GitHub Actions work exposed that the cloud runner only sees committed and pushed repository state. The rule is now recorded in `shared-procedures.md`, `tier2-agentic.md`, and `literature-search-protocol.md`.
- Scope: applies to all GitHub Actions-backed Tier 2 processes, including PubMed search, context scout, and synthesis handoff workflows.

### 2026-05-07: approved outputs folder convention
- Status: `Promote now`
- Why: `framing/` is for project positioning and argument scaffolding, not every completed deliverable. Final or agreed documents need a first-class approved home.
- Evidence: the repo now uses a four-folder approved structure: `framing/`, `sources/`, `syntheses/`, and `outputs/`; templates, session initialisation, shared procedures, registry guidance, and live project folders have been updated.
- Scope: applies to new projects and to existing projects as they migrate final grants, manuscripts, cover letters, policy briefs, reviewer packs, and circulation-ready documents.

### 2026-05-07: `memory.md` dashboard boundary and Tier 1 output rule
- Status: `Promote now`
- Why: `memory.md` is useful as a living project dashboard, but it must not become a route for unreviewed agent conclusions to enter trusted project memory. Final outputs need a clear default rule that they are drafted from Tier 1 approved content.
- Evidence: live project work around a published Conversation article exposed the need to distinguish operational memory updates from substantive claims. The rule is now recorded in shared procedures, Tier 1 and Tier 2 workflows, the memory template, and the project guardrails.
- Scope: applies repo-wide. `memory.md` may track operational state, links, open loops, completed actions, and claims already supported by Tier 1 approved material. New substantive claims, interpretations, literature conclusions, or recommendations require review/promotion or explicit user approval before being treated as settled project knowledge or used in final output documents.

### 2026-05-07: reviewer-pack workflow as a reusable project pattern
- Status: `Keep private`
- Why: the `nejm_ai_reviewers` project shows a useful repeatable shape for case-based reviewer identification: request pack template, working pack per case, explicit conflict/caution notes, email verification, and promotion of agreed packs to outputs.
- Evidence: multiple working reviewer packs now use the same structure and the project has a dedicated template.
- Scope: specific to Ewen's editorial workflow and should not be promoted to the public core repo.

## Full Repo Scan Summary, 2026-05-07

Fresh comparison of the private repo against `C:\Users\ewenh\Documents\agentic_workspace_core` found these promotion options:

1. Promote the four-folder approved structure now: update README, templates, registry, session-init, shared procedures, and the sample project with `approved/outputs/`.
2. Promote the approval-boundary hardening now: keep first-pass search/source notes in `working/` or `auto/` until explicitly approved; this touches shared procedures, source-note template, synthesis prompt, and literature-search protocol.
3. Promote the GitHub Actions preflight rule now: require commit/push of workflow dependencies before dispatch.
4. Promote the PubMed workflow now as a runnable first-pass cloud literature-search agent, including the PubMed workflow YAML, runner script, protocol template, and documentation.
5. Keep the reviewer-pack project pattern private because it is specific to Ewen's editorial workflow.
6. Keep private project content private: live project sources, grant/manuscript outputs, reviewer candidates, email/note destination details, and collaborator-specific material should not be copied into public core.

## How To Use This File

- Add one short entry when a new repo-level pattern emerges.
- Prefer decisions based on repeated use, not first impressions.
- Remove or downgrade entries if later experience suggests they were too local or too fragile.
