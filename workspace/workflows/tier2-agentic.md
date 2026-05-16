# Tier 2 Workflow: Agentic

Use this workflow when you want autonomous capture and organization.

## Default Behavior

- Raw source goes into `sources/`
- Agent writes notes into `auto/`
- Agent may update `memory.md` only with clearly bounded operational current-state changes, links, open loops, and status updates
- Agent may maintain indexes and activity logs automatically
- Approved memory remains untouched unless you explicitly ask for promotion
- Agent must not place unreviewed substantive claims, interpretations, literature conclusions, or recommendations into `memory.md` as if they were trusted project knowledge

## Agent Responsibilities

1. Record source metadata.
2. Generate a structured source note.
3. Add tags, cross-links, and related project references where helpful.
4. Update `auto/index.md`.
5. Update `memory.md` when the project snapshot has meaningfully changed, but only for operational state or for claims already supported by Tier 1 approved content.
6. Log major actions in `logs/activity.md`.

When updating `memory.md`, always link source entries to the local note or downloaded file.

## Human Responsibilities

1. Periodically review `auto/`.
2. Promote useful material into `approved/` when appropriate.

## Promotion Rule

Autonomous memory is useful working memory, but it should not be treated as trusted canonical memory until you promote it. Output documents should be created from Tier 1 approved content by default; `auto/` material can only be used in final deliverables after review/promotion or explicit user approval.

## Agent Mode Rule

- `general` is for broad project maintenance.
- `context_scout` is for scanning existing repo context only.
- `synthesis_agent` is for integrating supplied evidence, notes, and search results with current project framing.
- `pubmed_literature_search` is the first formal external-search workflow. It executes a saved PubMed protocol and writes a working search-results note.
- `literature_scout` is reserved for a future broader workflow with real external search capability and should not be used as a prompt-only cloud mode.

When a task requires PubMed retrieval, follow [literature-search-protocol.md](../repo/literature-search-protocol.md) and use the `PubMed Literature Search` workflow where appropriate. When a task requires Crossref, Semantic Scholar, journal, or web retrieval, continue to create a separate search-results note before synthesis until formal source-specific workflows exist.

Before dispatching any GitHub Actions-backed Tier 2 process, commit and push all required workflow, script, template, procedure, and project input files. The cloud runner only sees the repository state on GitHub, not local uncommitted changes.

## Possible Future Requirement

Tier 2 may later need a stricter `LLM-as-judge` layer for relevance control, especially in literature-heavy projects.

If adopted, that judging layer should help decide whether new material is:

- directly relevant to the project's core thesis
- only adjacent background
- too weakly connected to bring forward

This is not a current requirement, but it remains a plausible future upgrade for keeping Tier 2 focused.
