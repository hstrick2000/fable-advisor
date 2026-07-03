# Fable Advisor

**The smartest model runs the show. Cheaper models do the typing.**

Claude Code lets every subagent run on a different model — and lets the session itself run on a different model than its subagents. This plugin exploits that with the **architect pattern**: your session runs on **Fable 5**, Anthropic's most capable model, acting as a full-time architect. It owns requirements, decomposition, specs, and verification — and routes every implementation task to the cheapest adequate lane:

| Lane | Producer | Invocation | Route here when |
|---|---|---|---|
| Routine | Sonnet | `implementer` agent (default) | The spec fully determines the outcome |
| Subtle | Opus | `implementer` with `model="opus"` | A Sonnet miss is expensive — concurrency, security, hard debugging |
| Cross-vendor | GPT-5.5 | `codex-implementer` agent | Correctness-critical, or you want a non-Anthropic second implementation |
| Judgment | Fable 5 | `fable-advisor` agent | Commitment boundaries — see below |

Tokens route by volume: the expensive model emits the fewest tokens (judgment and specs), cheap models emit the most (code). Implementation mechanics are ~90% of a session's tokens and Sonnet handles them at near-parity — so this runs roughly 60% cheaper than Fable-for-everything, at higher quality than Sonnet-for-everything.

The plugin ships the **orchestration skill** — the routing doctrine that teaches the session when to use each lane, the five-part spec contract that makes context-free delegation safe, and the verification rules that keep cheap lanes honest.

## Install

```
claude plugin marketplace add DannyMac180/fable-advisor
claude plugin install fable-advisor
```

Then start your session as the architect:

```
/model fable
```

**Lite mode — one file, 30 seconds.** Don't want the full pattern? Copy [`agents/fable-advisor.md`](agents/fable-advisor.md) into `~/.claude/agents/` and keep your session on Sonnet. You get advisor consults at commitment boundaries without the orchestration layer (see "Advisor-only mode" below).

## Requirements

- **Claude Code ≥ 2.1.170** with a subscription that includes Fable 5 (Pro, Max, Team, or Enterprise — all current consumer plans qualify).
- **No Fable access** (e.g. API-key billing)? Use `/model opus` for the session and change `model: fable` → `model: opus` in the advisor file. Same pattern, model tiers shift down one.
- **Codex lane (optional):** the `codex-implementer` agent needs the [OpenAI Codex CLI](https://github.com/openai/codex) installed and authenticated (`npm i -g @openai/codex`, then `codex login`). Without it the agent reports `STATUS: unavailable` — the other lanes are unaffected.
- Heads-up: if a pinned model isn't available on your account, Claude Code silently falls back to your session model — the pattern degrades quietly rather than erroring. If results feel unremarkable, check your plan. (This quiet fallback applies only to Claude model pins — the codex lane always fails loudly with a structured error.)

Model resolution order in Claude Code: `CLAUDE_CODE_SUBAGENT_MODEL` env var → per-invocation `model` parameter → agent frontmatter → session model.

## Use it

With the session on Fable, just ask for work — the orchestration skill routes it:

```
Add rate limiting to our public API. Design it, delegate the
implementation, and verify the evidence before you call it done.
```

The architect writes the spec, picks the lane (rate limiting touches concurrency — likely `implementer` with `model="opus"`), reads the diff and verification evidence when the report comes back, and only then reports done.

To make the doctrine always-on, add one line to your project's `CLAUDE.md`:

```
You are the architect: delegate all implementation through the
orchestration skill's routing table and verify evidence before
accepting any lane's report.
```

## Commitment boundaries

Even the architect gets a second opinion. The `fable-advisor` agent is a read-only skeptic — consulted before architecture decisions, migrations, API designs, and whenever a problem has resisted two attempts. It reads your actual code and returns a verdict in under 300 words. It never implements. Running it from a Fable session still pays: it sees the code fresh, without your conversation's accumulated assumptions.

## Advisor-only mode (the original pattern)

The inverse arrangement, for when you'd rather keep the session cheap: run the session on Sonnet and consult `fable-advisor` only at commitment boundaries.

```
Migrate our checkout sessions from Postgres to Redis — plan it,
consult your advisor before committing, then implement.
```

A typical consult costs cents. To make it automatic, add to your project's `CLAUDE.md`:

```
Before committing to any architecture decision, migration, or refactor
touching 3+ files, consult the fable-advisor agent and act on its verdict.
```

## FAQ

**Is this Anthropic's "advisor tool"?** No — that's a server-side API feature. These are plain Claude Code subagents plus a skill: readable, editable, no beta flags.

**Does this work on claude.ai?** No — subagent model routing is Claude Code only (CLI, desktop, VS Code, web).

**Why not just run everything on Fable?** You can. It's excellent. It's also ~3× the per-token cost of Sonnet, and most of a session's tokens are implementation mechanics that Sonnet handles at near-parity. Spend the premium where judgment lives.

**Upgrading from v1?** Nothing breaks: the `fable-advisor` and `implementer` agents are unchanged, and advisor-only mode works exactly as before. v2 adds the orchestration skill and the codex lane, and flips which pattern the docs lead with.

**Why a GPT-5.5 lane in a Claude plugin?** Vendor diversity. Models from one family share blind spots; an independent implementation from a different lineage catches what same-family review misses. The architect stays Claude — the lane is a producer, not a judge.

## License

MIT
