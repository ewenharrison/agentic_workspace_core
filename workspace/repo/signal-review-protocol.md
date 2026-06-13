# Signal Review Protocol

Use this protocol for repeated review of incoming signals: messages, feeds, alerts, calendars, dashboards, task systems, or other time-windowed streams.

The goal is to notice project-relevant signals, route them into the right project context, and suggest safe next actions. This is not an automation licence to mutate external systems.

## Core Lifecycle

1. Define the source stream, scan window, query or filter configuration, item limits, and output location.
2. Collect a bounded read-only scan packet.
3. Write a project-facing digest from the packet.
4. Validate the digest against required sections and guardrails.
5. Advance completed scan state only after validation succeeds.
6. Route project-specific recommendations through copyable handoff prompts.

## Execution Boundary

Document whether collection can run in the sandbox or must run in a host-bound environment.

The workflow should state:

- what source is accessed
- what credentials or local sessions are required, if any
- what the collection command is allowed to do
- which mutations are forbidden
- where temporary packets, pending state, completed state, logs, and digests live

Access escalation for collection does not authorise posting, sending, replying, editing, importing, deleting, moving, marking, archiving, or updating completed state unless separately authorised.

## Folder Pattern

Use a workflow-specific folder under `workspace/` when the signal stream cuts across projects.

Recommended layout:

```text
workspace/<signal-workflow>/
  README.md
  rules.md
  scheduling.md              optional
  platforms/                 optional source/query config
  tmp/                       ignored temporary scan packets
  state/                     ignored completed and pending scan state
  logs/                      ignored or minimal operational logs
  working/                   dated digests
```

Project-specific imports, if later approved, should go under the target project, usually `sources/` for raw or near-raw source material and `working/` for agent-authored summaries.

## Scan Packet Rule

The scan packet should be bounded and reproducible enough for review.

Include:

- scan start and end
- source name and access route
- query/filter track names
- item count and item identifiers
- enough item metadata to support triage
- source URLs or stable identifiers where available
- explicit truncation notes for long text
- pending state path, if state is used
- proposed digest path

Do not place temporary scan packets in project `approved/`.

## Digest Rule

Digest files should be short, date-prefixed, and project-facing.

Recommended sections:

- scan window, source, query/filter tracks, and returned-item count
- top signals or top issues
- project-relevant watchlist
- suggested imports, each requiring explicit user approval
- suggested replies, posts, edits, tasks, or external actions as draft ideas only
- no-action summary
- query/filter tuning notes
- next steps

Do not fill the digest with weak items. If fewer than five items matter, report fewer.

## Ranking Rule

Rank signals by:

- relevance to active projects or durable research interests
- likely impact on project direction, deadlines, collaborators, funders, policy, papers, datasets, or methods
- credibility of the source
- novelty relative to known project context
- actionability
- time sensitivity
- external attention or recurrence, only as secondary evidence

## Handoff Prompt Rule

Every project-specific recommendation should include a short prompt for the relevant project chat.

Use this pattern:

```text
Initialise project <project-slug>. From the <signal workflow> digest at <digest-path>, handle the <topic> item. Do not import raw signal content or mutate external systems unless I approve. First summarise the recommended import, synthesis, or action.
```

If no project exists:

```text
Start a <topic> chat. From the <signal workflow> digest at <digest-path>, handle the <topic> item. Do not import raw signal content or mutate external systems unless I approve. First summarise the recommended action.
```

## Import Rule

Do not import raw signal content automatically.

If a signal should become project evidence, recommend a target path such as:

```text
workspace/projects/<project-slug>/sources/<signal-type>/YYYY-MM-DD-<short-title>.md
```

Create that file only after explicit user approval. Agent-authored summaries of signals start in `working/` unless the user explicitly requests an approved note.

## State Rule

Keep pending state separate from completed state.

- The collector may write pending state describing the packet it just produced.
- The digest writer or wrapper may validate the digest.
- Completed state advances only after validation succeeds.
- If validation fails, leave completed state unchanged so the next run can retry the same window.

Validation should check that the digest is not a scaffold, contains required sections, obeys item-count limits, and includes handoff prompts for project-specific recommendations.

## Mutation Guardrail

Unless explicitly authorised in the user request and workflow docs, do not:

- send, post, reply, forward, or publish
- accept, decline, create, edit, move, delete, archive, mark, like, bookmark, follow, or otherwise change source-system state
- create external tasks or tickets
- import raw source material into a project
- expose private or non-public details beyond the workflow's approved scope

Suggested external actions should remain Markdown drafts or recommendations until approved.
