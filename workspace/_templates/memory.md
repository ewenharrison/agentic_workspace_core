# Project Memory Snapshot

Use this as a living project dashboard, not as a route for unreviewed agent conclusions to become trusted content. Record operational state, links, decisions, open loops, and claims already supported by Tier 1 approved material. Do not add new substantive claims, interpretations, literature conclusions, or recommendations unless reviewed or explicitly approved.

## Current Snapshot
3 to 6 lines on where the project stands right now.

## Current Objective
One sentence on the immediate aim.

## Key Claims We Are Carrying Forward
- `[C1]` Claim 1
- `[C2]` Claim 2
- `[C3]` Claim 3

## Open Loops
- `[Q1]` Open question 1
- `[Q2]` Open question 2

## Active Sources
- `[W1]` [Working source or draft title](./working/example-working-note.md): why it matters, awaiting review
- `[S1]` [Approved source title](./approved/sources/example-source-note.md): why it matters, only after explicit human approval
- `[O1]` [Approved output title](./approved/outputs/example-output.md): final or agreed deliverable, only after explicit human approval

## What Changed Recently
- Most recent update
- Note major workflow changes, tool confirmations, or newly enabled operating modes here.

## Next Actions
- [ ] Action 1
- [ ] Action 2

## Suggested Next Prompts
- Prompt 1
- Prompt 2

## Guardrails
- What should be treated as settled
- What should still be treated as provisional
- `approved/` is human-gated. Do not create or move files there without explicit human approval or an explicit instruction to promote a named draft.
- Final output documents should be drafted from Tier 1 approved content by default.
- `working/` and `auto/` material can inform suggestions, but should not be used as final-output source material unless reviewed/promoted or explicitly approved.
- If Teams sharing is used, default to the adaptive-card webhook workflow rather than plain text.
- Always link every source entry to the local note or downloaded file so the project can be navigated directly from `memory.md`.
