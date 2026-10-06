# Email Review (Windows Pilot)

Optional project-aware email review for Agentic Workspace Core. It collects bounded inbox excerpts through classic Outlook, produces a digest with proposed replies and project handoff prompts, and remembers completed work. It never sends mail or changes Outlook messages.

## Requirements

- Windows with Windows PowerShell 5.1 (`powershell.exe`). No Python, package manager, or extra PowerShell modules are needed for manual review.
- Classic Outlook installed, signed in, synchronised, and already open in the same logged-in Windows user session.
- A private workspace containing this module and your selected projects.
- An interactive agent for manual review, or an OpenAI API key and a model supporting Responses structured outputs for unattended review.

New Outlook, Outlook on the web, macOS, Gmail, and Microsoft Graph are not supported by this first connector. Microsoft's [feature comparison](https://support.microsoft.com/en-gb/outlook/getstarted/feature-comparison-between-new-outlook-and-classic-outlook?OCID=Learn_Admin_Overview) lists the Outlook Object Model as unsupported in new Outlook. Graph is the planned next connector.

Outlook access must run on the host when the agent sandbox cannot attach to desktop COM. Host access does not require running as administrator. The module attaches to an existing Outlook session and leaves it open; it never starts, closes, or force-stops Outlook.

## Guided Setup

Open your private workspace in your IDE and ask:

```text
Set up email review using modules/email-review/README.md.
Run the synthetic demo, check classic Outlook access, help me select
my mailbox and the projects to use, then collect one small manual batch.
Explain where the content will be processed before reading it with an LLM.
Show me the resulting digest. Leave scheduling disabled for now.
```

Alternatively, run these commands in Windows PowerShell from the workspace root:

```powershell
.\modules\email-review\email-review.ps1 demo
.\modules\email-review\email-review.ps1 doctor
.\modules\email-review\email-review.ps1 setup
```

`demo` runs synthetic tests and prints a sample digest without accessing mail or the network. `doctor` checks attachment to classic Outlook and lists mailbox names without reading messages. `setup` asks which mailbox and projects to use and creates ignored local configuration. For a noninteractive agent, setup also accepts `-Mailbox "<exact mailbox display name>" -Projects project-one,project-two`; use `-Projects @()` for no project context when invoking from PowerShell.

Only the explicitly selected `project.md` and `memory.md` excerpts are included. Nested project slugs work, for example `research/trial-one`. New projects are not automatically added. With no selected projects, the digest provides general triage.

## First Manual Review

```powershell
.\modules\email-review\email-review.ps1 scan
```

The first window covers seven days and each batch includes at most 20 messages. The command reports `workspace/email-review/pending.json` and `workspace/email-review/review.json`. Ask your agent to follow [review-prompt.md](review-prompt.md), fill the review, and run:

```powershell
.\modules\email-review\email-review.ps1 complete
.\modules\email-review\email-review.ps1 status
```

Digests appear in `workspace/email-review/working/YYYY-MM-DD-HHmmss-<id>-digest.md`. Each relevant project gets a copyable continuation prompt. The command prints the exact path; `status` reports the latest digest and any unfinished window. There are no email or external notifications.

When more batches remain, run `scan` and `complete` again. Repeated scans reuse a pending packet until it is completed. A message limit never marks an unfinished window complete. Each batch must account for every returned message, even when no action is needed.

## Configuration And Data

The configuration is `workspace/email-review/config.json`. Setup does not overwrite an existing configuration. Defaults:

| Setting | Default | Meaning |
| --- | --- | --- |
| `Scope` | `focused` | `focused` or `all` inbox messages |
| `UnknownClassification` | `include` | Include/exclude messages whose Focused status is unavailable; counts are disclosed |
| `DaysBack` | `7` | Initial scan history |
| `MaxMessages` | `20` | Messages per batch, maximum 100 |
| `MaxScanItems` | `200` | Previously unexamined items per batch |
| `BodyChars` | `2500` | Maximum body excerpt; zero means headers only |
| `ProjectChars` | `1800` | Maximum characters per selected project file |
| `MaxBatchesPerRun` | `5` | Work/cost bound per scheduled invocation |
| `ApiEnabled` | `false` | Explicitly enabled API transfer |
| `Enabled` | `true` | Master switch for scans and runs |

Runtime files, including digests, are excluded from Git. They contain private data and remain accessible to your local user, backup software, and any folder-sync service you use. Git ignore is not encryption. The module does not automatically delete local records; remove old digests and `review.json` according to your retention needs after review. Preserve `state.json` and unfinished `pending.json` to retain scan continuity.

The collector reads sender display name, recipients, subject, receipt time, classification, and bounded plain-text bodies. It does not read attachments, calendar, Sent Items, other folders, or the user profile. A pending packet also contains selected project excerpts. Passing that packet to a hosted interactive agent sends its content according to that agent's processing arrangements.

Changing mailbox or inbox scope requires an explicit new history: complete pending work, disable scheduling, move `state.json` aside, edit the configuration, then resume. For a different mailbox, rerun setup after moving both config and state aside. Keep the previous files private. Body/project limit changes apply to new packets; a pending packet retains its original context.

## Optional API Review And Scheduling

API mode sends bounded message metadata/bodies and selected project excerpts to `https://api.openai.com/v1/responses`. It uses structured output without tool access and sets `store: false`. This does not promise zero retention under every account policy. Review the provider's [data controls](https://developers.openai.com/api/docs/guides/your-data) and your organisation's rules before enabling it. API usage is billed separately from interactive subscriptions.

Set `OPENAI_API_KEY` in your Windows **user environment** using Windows environment settings or your approved credential process. Never put the key in chat, config, Git, or a scheduled-task command. Choose a Responses model available to your account that supports [structured output](https://developers.openai.com/api/docs/guides/structured-outputs?api-mode=responses). No model is silently selected for you.

```powershell
.\modules\email-review\email-review.ps1 enable-api -Model "<model-id>" -AcceptApiTransfer
.\modules\email-review\email-review.ps1 run
```

`run` retries API failures briefly and retains pending work if it cannot produce a validated digest. It processes at most the configured batch count; a later run continues the remaining window. It does not send email or create Outlook drafts.

After completing a live review, enable a weekday schedule:

```powershell
.\modules\email-review\email-review.ps1 schedule -Time "08:00"
```

The Windows task runs in your logged-in session at the machine's local time. Outlook must remain open. Missed runs can catch up when Windows makes the task available. Overlapping runs are prevented, including manual/scheduled collisions. The task name includes the workspace path hash so installations do not overwrite one another. It runs with ordinary user privileges. GitHub Actions only runs synthetic tests; it never receives your mailbox credentials or email.

```powershell
.\modules\email-review\email-review.ps1 status
.\modules\email-review\email-review.ps1 disable
.\modules\email-review\email-review.ps1 uninstall
```

`disable` and `uninstall` remove this workspace's scheduled task and disable further scans. Both retain module files and private records for recovery. No mailbox content is deleted. Set `Enabled` back to `true` in config to resume manual reviews; run `schedule` to re-enable scheduling. Moving the workspace requires removing the old schedule first and registering one at the new path.

## Troubleshooting And Limits

- **Cannot attach:** use classic Outlook and `powershell.exe` in the same signed-in session. Ask your agent for host execution if its sandbox blocks COM. Organisational Outlook security prompts/policies may still restrict access.
- **No digest:** run `status`. Correct access, API configuration, or the review JSON, then retry. Failed runs do not advance checkpoints. Detailed source content is not logged to the console.
- **Focused classification unavailable:** the connector uses a classic Outlook MAPI property; absent/unrecognised values remain `unknown`. Choose whether to include them. This is not a guarantee of exact visual Focused-tab matching on every installation.
- **Busy inbox:** batch caps preserve an unfinished fixed time window and remember examined IDs. Tied timestamps cannot skip messages between batches. A two-minute overlap catches short sync delays and deduplicates already-seen messages.
- **Offline/sync delays:** this reads Outlook's locally available Inbox. Mail moved out of Inbox before collection is outside its scope; delays longer than the overlap may require deliberately rescanning an earlier window. It is not an archival or compliance capture service.
- **Power interruption:** state replacement is atomic and a pending batch survives failure. If interrupted after state commit, the next command cleans up the already-completed packet.
- **Review quality:** structural validation checks coverage, IDs, selected projects, and placeholders. It cannot prove the model interpreted an email correctly. Digests remain provisional.

Calendar context, reply tracking, outbound mail, and external reminder services are deliberately absent from this pilot. Future mailbox connectors should produce the same versioned packet and use the existing review and completion steps.

## Development And Promotion

Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File modules/email-review/tests/run-tests.ps1`.
The suite uses synthetic data and disposable directories only. On restricted agent hosts, atomic replacement tests may need approved host execution. CI runs it on Windows without mail access or API secrets.

The maintained source is `modules/email-review/` in the private development repo. Promotion includes only that directory, generic documentation, and its test workflow. Never export live email state, packets, configuration, digests, private mailbox rules, or personal editorial filters. Core-only README edits must be reconciled into `README.core.md` before future exports.
