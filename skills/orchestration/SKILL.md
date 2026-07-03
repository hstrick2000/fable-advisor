---
name: orchestration
description: Routing doctrine for the architect-as-orchestrator pattern — how a session running the smartest model delegates implementation to cheaper or cross-vendor lanes. USE WHEN delegating implementation work, choosing between implementer/codex-implementer lanes, escalating a subagent to opus, writing a spec for a subagent, deciding whether to consult fable-advisor, or running any multi-task build where the session is the architect.
---

# Orchestration — the architect's routing doctrine

The session is the architect: it owns requirements, architecture, decomposition, specs, routing, and verification. It should almost never type implementation code. Every implementation task gets routed to the cheapest lane that is adequate for it — escalation is deliberate, per task, never a fixed binding.

## The lanes

| Lane | Producer | Invoke | Route here when |
|---|---|---|---|
| Routine | Sonnet | `implementer` agent (frontmatter default) | The spec fully determines the outcome: boilerplate, wiring, CRUD, mechanical edits, straightforward features. **Default lane.** |
| Subtle | Opus | `implementer` with `model="opus"` | A Sonnet miss is expensive: concurrency, non-trivial algorithms, security-sensitive paths, hard debugging, wide-blast-radius refactors. |
| Cross-vendor | GPT-5.5 | `codex-implementer` agent | Correctness/completeness is critical enough to want a different model family, or you want an independent implementation to compare against a Claude lane. Requires the codex CLI. |
| Judgment | Fable 5 | `fable-advisor` agent | Not an implementation lane. See "Commitment boundaries" below. |

Deciding rule: how much does the outcome depend on judgment the spec can't capture? None → Sonnet. Some, and mistakes are costly → Opus. When two lanes seem equal, take the cheaper one — you will verify anyway.

Opus vs codex is not a capability question — it's a failure-distribution question. Opus buys *more* capability within the same model family; codex buys a *different* family whose blind spots don't overlap Claude's. Route to codex when same-family review is the risk (the architect and an Opus implementer would miss the same things), or when you'll race both lanes and pick the stronger diff.

If the codex lane returns `unavailable` or `timeout`, re-route the same spec to the Opus lane and say so explicitly in your report — never quietly absorb the downgrade, because the caller may have chosen that lane for vendor diversity.

## The spec contract

Implementers share none of your conversation context. Every delegation prompt carries all five parts:

1. **Objective** — what to build or change, one paragraph
2. **Files** — exact paths to create or modify
3. **Interfaces** — signatures, types, or API shapes the code must match
4. **Constraints** — project conventions, things not to touch
5. **Verification** — the command(s) that prove it works

A spec you can't finish writing is a signal the decision isn't made yet — that's architect work, not a reason to hand the ambiguity to a cheaper model.

## Parallelism

Independent specs (no shared files, no ordering dependency) launch as parallel agents in a single message. Sequential chains and single-file surgery stay serial. For high-stakes work, a pick-the-stronger-diff race — `implementer` and `codex-implementer` on the same spec, architect judges — buys cross-vendor confidence for one extra lane's cost.

## Commitment boundaries

Consult `fable-advisor` (read-only, verdict in under 300 words) at the moments that decide whether the next hour is wasted:

- Before committing to an architecture, data migration, API shape, or refactor strategy
- Whenever the same problem has resisted two distinct attempts
- Once before declaring a multi-step deliverable done

Pass it the decision, the constraints, and the options considered. Act on the verdict or surface the disagreement — never silently ignore it. (If the session itself already runs on Fable, the advisor still earns its keep as a context-clean skeptic reading the actual code.)

## Verification

Reports are claims, not evidence. Before accepting any lane's work: read the diff, and re-run the verification command (or spot-check its quoted output against the working tree). "Should work", "tests should pass", or a report with no command output means the task is not done. An implementer that reports a spec gap gets a corrected spec, not a "use your judgment".
