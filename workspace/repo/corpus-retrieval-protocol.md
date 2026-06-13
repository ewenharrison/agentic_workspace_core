# Corpus Retrieval Protocol

Use this protocol when building a publication, website, document, dataset, or other multi-item corpus from external sources.

The purpose is to make retrieval auditable, legitimate, resumable, and safe before extraction or synthesis begins.

## Required Separation

Keep these artefacts separate:

- retrieval/access plan
- executed search or enumeration results
- retrieval manifest
- raw files or snapshots
- extraction outputs
- coding schema
- synthesis or interpretation

Planning files, manifests, extraction drafts, and coding drafts should normally live in `working/` with `YYYY-MM-DD-` filenames. Raw source files or snapshots can live under `sources/` when needed for verification.

## Scope Definition

Before collecting at scale, define:

- corpus aim
- source sites, databases, repositories, or APIs
- inclusion and exclusion criteria
- expected item types
- required metadata fields
- target raw artefacts, if any
- reuse, copyright, privacy, and access boundaries
- stopping conditions
- final deliverables

## Access Smoke Test

Run a small smoke test before large-scale retrieval.

Record:

- date
- URL or endpoint
- access route
- status code or error
- content type
- redirect target, if any
- whether content is usable
- whether the route appears public, credentialed, host-bound, or blocked
- whether a browser-like route differs from a command-line route

Do not treat a single failed request as proof that content is unavailable. Follow the multi-route checks in [literature-search-protocol.md](literature-search-protocol.md) when access differs by client, network, redirect, JavaScript, cookies, or sandbox boundary.

## Credential Boundary

Do not store credentials in the repo.

Forbidden in tracked files:

- passwords
- API tokens
- bearer tokens
- reusable cookies
- browser profiles
- session exports
- credential files
- copied secrets from environment variables

If credentialed access is necessary, prefer a visible local login or an operating-system/user secret store. Any local secret path must be outside the repo or explicitly ignored. Document the boundary without recording the secret.

## Stratified Pilot

After the smoke test, retrieve a small stratified sample before collecting the whole corpus.

Choose examples that cover:

- current and older items
- each major item type
- expected public and credentialed cases
- small and large files
- HTML or metadata pages
- raw document downloads, if relevant
- edge cases likely to fail

Proceed to full retrieval only if the sample confirms the access route, content type, naming convention, and manifest fields are fit for purpose.

## Retrieval Manifest

Maintain a manifest for every attempted item.

Recommended fields:

- item identifier
- title or short label
- source URL or endpoint
- retrieval route
- status
- status code
- content type
- byte size where available
- effective URL
- retrieval date/time
- local path, if saved
- checksum, if saved
- extraction status
- error or follow-up note

Use explicit statuses such as:

- `metadata_only`
- `raw_file_ok`
- `html_ok`
- `blocked`
- `not_found`
- `needs_login`
- `rate_limited`
- `challenge`
- `non_target_content`
- `manual_check`

## Conservative Retrieval

Use conservative batching and clear hard stops.

Stop or pause when you see:

- rate limits
- access challenges
- repeated redirects to login or anti-bot pages
- unexpected content types
- corrupted or partial files
- many repeated failures from the same route
- terms-of-use or copyright concerns

Record failures in the manifest rather than smoothing them over.

## Raw File Rule

Save raw files only when needed for verification, extraction, or legitimate local review.

Do not redistribute raw full-text, licensed, private, or otherwise restricted material. Do not paste long raw text into notes when a local source path, checksum, and concise extraction output will do.

## Extraction Rule

Keep extraction outputs separate from interpretation.

Extraction outputs should record:

- source item identifier
- source local path or URL
- extraction route
- extracted metadata fields
- missing fields
- uncertainty
- extraction date
- whether manual review is needed

Automated extraction and coding are provisional until reviewed. Store them in `working/` or `auto/`, not `approved/`, unless the user explicitly approves promotion.

## Publication Corpus Schema

For article-level or publication-level reviews, start from [../_templates/publication_corpus_review_schema.md](../_templates/publication_corpus_review_schema.md) and prune fields that are not needed.

Do not let the schema imply that automated labels are final. Include `coding_status`, `needs_manual_review`, and `coding_notes` fields for uncertainty.

## Synthesis Handoff

Only pass a corpus to synthesis after these exist:

- scope definition
- retrieval manifest
- confirmed source set or inventory
- extraction or coding draft
- known access and reuse limitations

The synthesis prompt should name those files explicitly and should not ask the agent to infer access, coverage, or citation status from memory.
