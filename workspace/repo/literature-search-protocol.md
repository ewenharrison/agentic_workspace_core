# Literature Search Protocol

Use this protocol when a task requires real external literature retrieval.

The current Tier 2 cloud runner does not search PubMed, Crossref, Semantic Scholar, journal websites, or the open web. It can only reason over supplied repo context. A search strategy file is therefore not enough: an executed search must produce a separate search-results file.

For multi-item publication, website, document, dataset, or other corpus retrieval, also use [corpus-retrieval-protocol.md](corpus-retrieval-protocol.md). That protocol covers access smoke tests, credential boundaries, retrieval manifests, raw file storage, and extraction status.

## Required Separation

Keep search planning and search execution separate.

Required filenames:

- `working/YYYY-MM-DD-search-strategy-<topic>.md`
- `working/YYYY-MM-DD-search-results-<topic>.md`

## Search Strategy File

The strategy file should include:

- research question or review aim
- databases or venues to search
- exact Boolean strings
- MeSH or controlled-vocabulary terms where relevant
- inclusion and exclusion criteria
- priority venues or journals
- planned screening categories

For a cloud PubMed run, prefer the structured template at [../_templates/pubmed_search_protocol.md](../_templates/pubmed_search_protocol.md). The PubMed workflow requires a `## PubMed Query` section with the exact query in a fenced `text` block.

## Cloud PubMed Search Workflow

Use the `PubMed Literature Search` GitHub Actions workflow when a saved protocol should be executed in the cloud.

Preflight requirement:

- Commit and push the saved PubMed protocol file before dispatching the workflow.
- Commit and push any workflow YAML, script, template, or procedure changes that the PubMed workflow depends on before dispatch.
- Confirm the workflow is available on GitHub with `gh workflow list` or the GitHub Actions UI before running it.
- Remember that GitHub Actions cannot see local uncommitted search strategies, scripts, or workflow files.

Inputs:

- `project_slug`: the target project folder under `workspace/projects/`
- `protocol_path`: repo-relative path to the saved PubMed protocol file
- `max_results`: number of PubMed records to return, capped at 500 for the first implementation
- `sort`: `relevance`, `pub date`, or `most recent`
- `run_synthesis`: whether to run `synthesis_agent` on the returned search-results file in the same PR
- `synthesis_prompt`: optional extra instruction for the synthesis handoff

The workflow writes a PubMed results note into `workspace/projects/<project>/working/`, updates the project activity log, updates `workspace/runs/agent-runs.md`, and opens a PR. If synthesis is enabled, the same PR also contains the provisional Tier 2 synthesis note in `auto/`.

For now this workflow searches PubMed only. Do not use it as evidence of Embase, arXiv, medRxiv, Google Scholar, journal-site, or broader web coverage.

## Search Results File

The results file should include:

- search date
- person or agent who ran the search
- database or source searched
- exact query used
- hit count where available
- filters used
- candidate records with title, authors, year, venue, DOI/PMID/URL where available
- short inclusion rationale
- exclusion rationale for near-misses
- whether each source is directly on-point, adjacent but useful, or background only
- whether the user or known project collaborators appear in the author list, acknowledgements, consortium byline, or source provenance
- verification status for each citation, including the route used to confirm it: journal page, DOI record, PubMed, Crossref, local PDF, official organisation page, or other named source

Search-results files and first-pass source summaries should normally be saved in `working/`. They are evidence-gathering artefacts, not approved memory. Do not write search-derived summaries into `approved/` until the user has reviewed and explicitly approved them for promotion.
All non-placeholder files created in `working/` must begin with `YYYY-MM-DD-`.

## Citation Use Rule

- Do not cite sources from memory or plausible recall alone.
- Only use references that have been confirmed through an executed search, local source file, DOI/PubMed/Crossref record, journal page, or official organisation page.
- When drafting fact-bearing prose for the user, include internal citations or source keys against factual claims unless the user explicitly asks for clean final copy.
- If a source is not yet confirmed, write `[source needed]` rather than inventing or approximating a citation.
- Maintain a local source map for substantial drafts so citation keys can be traced back to confirmed records.

## Authorship And User-Connection Check

For each high-priority source, check whether the user appears to be directly connected to the work. Use loaded `profile/` identity, project memory, known collaborator names, author initials, affiliations, and source provenance.

Classify user connection where relevant:

- `User-authored`: the user appears in the author list or consortium author group.
- `User-led or consortium-linked`: the user appears to have led, coordinated, or contributed through a named collaborative group.
- `Collaborator-authored`: a known collaborator or project partner appears.
- `External`: no obvious direct connection.
- `Unclear`: possible name/initials match but insufficient evidence.

If a source is user-authored or directly connected, state this plainly in the working note and use it to sharpen interpretation. For example, prior user-authored work may be best framed as an established foundation or continuity point, not as generic external literature. Do not overclaim authorship from initials alone; mark uncertain matches as `Unclear`.

## Web Access Failure Checks

Do not treat a single failed request as proof that a page is unavailable. Web access is client-dependent: sandbox proxying, TLS handling, redirects, user-agent differences, JavaScript, and institutional hosting layers can all produce false negatives.

Before recording that a public URL cannot be accessed, attempt at least two materially different routes where available:

- browser or web-fetch tool
- local PowerShell `Invoke-WebRequest`
- `curl` with `-L` to follow redirects
- `curl` with a normal browser user-agent
- the explicit redirected URL if a `Location` header is visible
- an unrestricted retry when the first failure looks sandbox-, proxy-, TLS-, DNS-, or connection-related

Classify the result:

- `Accessible`: any route returns usable content.
- `Content-level failure`: the server returns a stable `404`, `403`, or equivalent across more than one route.
- `Environment/client failure`: errors mention proxying, TLS, connection close, DNS, sandbox denial, or differ across routes.
- `Unresolved`: checks conflict and no route returns usable content.

For any non-accessible or conflicting result, record the date, URL, method, status code or error text, redirect target, and conclusion in the search-results note. If a route succeeds, save a local snapshot or source note when the page is important for future verification.

## Agent Handoff

Only after a search-results file exists should the material be passed to a `Synthesis Agent`.

The Synthesis Agent should be asked to integrate a named results file, not merely a search strategy.

Example:

```text
Act as Synthesis Agent. Use workspace/projects/<project>/working/YYYY-MM-DD-search-results-<topic>.md as the input evidence. Integrate the findings with memory.md, project.md, approved notes, and current open questions. Do not promote anything directly to approved memory.
```

## Capability Boundary

- `context_scout`: scans existing repo context only.
- `synthesis_agent`: integrates supplied context and search results.
- `pubmed_literature_search`: executes a saved PubMed protocol through NCBI E-utilities and writes a working search-results note.
- `literature_scout`: reserved for a future broader workflow that can retrieve external literature across multiple sources.

Until a broader external-search workflow exists, do not trigger `literature_scout` as a cloud mode. Use the PubMed workflow for PubMed-only retrieval.

## Guardrail

If a note claims to have run a literature search but lists only repo files as evidence, treat it as a context-scout note, not as search results.

If a note was generated from web or literature search results without explicit human approval, treat it as `working` or `auto` material even if it is polished, well cited, or written in a source-note format.
