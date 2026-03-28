---
name: lesson-keeper
description: >
  Use this skill when you or your agent is corrected, makes a mistake, or needs to durably log
  a learning, feature request, error, or knowledge update. Built specifically for OpenClaw —
  unlike generic correction-logging skills, lesson-keeper enforces a three-place atomic write
  so corrections survive across sessions, and automatically promotes recurring mistakes
  (3+ occurrences) into iron rules with verifiable enforcement commands in your agent config.
  Trigger phrases: "log this", "record this mistake", "I was wrong about", "don't forget",
  "feature request", "I already told you", "this keeps happening", "third time this week".
---

# Lesson Keeper

> **Why this exists**: A correction that's only acknowledged in conversation evaporates between sessions. A correction written to one place only gets siloed. Only writing to all three places simultaneously — mistake log (what happened), hot memory (don't repeat next time), and pattern library (is this a recurrence?) — creates durable behavioral change.

---

## Quick Reference

| Situation | Action | Script shortcut |
|-----------|--------|----------------|
| Corrected by user | Three-step atomic op (below) | `log-correction.sh --title ... --scene ... --error ... --cause ... --fix ... --category <type>` |
| Command/script fails | Log error + root cause | `log-correction.sh --type error` |
| Better method found | Add GOOD entry | Edit `references/bad-good-examples.md` manually |
| User requests missing feature | Log feature request + CONTEXT留痕 | `log-correction.sh --type feature-request --title ... --need ... --scene ... --priority ... --impl ...` |
| exec command fails (non-zero exit) | Record error context | `log-correction.sh --type error --title ... --error ... --context ...` |
| New fact / knowledge update | Write learning record | `log-correction.sh --type knowledge --title ... --fact ... --source ...` |
| BAD entry Recurrence-Count ≥ 3 | Promote to iron rule | See [promotion-rules.md](references/promotion-rules.md) |
| Weekly review | Weekly scan | Read `references/bad-good-examples.md`, check all BAD entries |

Script path: `~/.openclaw/workspace/.agents/skills/lesson-keeper/scripts/log-correction.sh`

---

## The Three-Step Atomic Operation

When corrected, these three steps must all complete in the same session turn. Here's **why each step is non-negotiable**:

**Step 1 — `memory/mistake-log.md`**: The detailed record. Without this, root causes get lost. Future review sessions need this context to understand patterns, not just symptoms.

**Step 2 — `CONTEXT.md` lessons section**: The hot memory. This file is read every session. Without this, the correction doesn't exist for the next session — the agent starts fresh and repeats the error.

**Step 3 — `references/bad-good-examples.md`**: The pattern tracker. Without this, you can't detect recurrence. Three separate mistakes that share the same root cause look like three separate one-offs — until Recurrence-Count reveals otherwise.

**All three or none is fixed.** Partial logging feels like fixing but isn't.

### Shortcut: use the script (preferred)

Calling the script is the preferred way to execute the three steps — it's faster, atomic, and eliminates formatting errors.

```bash
bash ~/.openclaw/workspace/.agents/skills/lesson-keeper/scripts/log-correction.sh \
  --workspace ~/.openclaw/workspace \
  --title "Skipped routing step" \
  --scene "Did task directly instead of routing to the appropriate agent" \
  --error "Violated routing rule: task type X goes to Agent Y" \
  --cause "Thought it was 'just two lines'" \
  --fix "Identified violation, will route correctly going forward" \
  --category "routing"
```

The script handles all three writes atomically. See [logging-formats.md](references/logging-formats.md) for entry formats.

For **feature requests**, use the `--type feature-request` variant — it writes to `feature-requests.md` AND leaves a trace in `CONTEXT.md` so the request survives to the next session:

```bash
bash ~/.openclaw/workspace/.agents/skills/lesson-keeper/scripts/log-correction.sh \
  --type feature-request \
  --workspace ~/.openclaw/workspace \
  --title "Auto-send summary after pipeline completes" \
  --need "After a pipeline completes, automatically send a brief summary to the user" \
  --scene "User wants to see results inline without navigating to another channel" \
  --priority high \
  --impl "Add notify_user() step at end of pipeline script"
```

---

## Detection Triggers

Automatically recognize these signals and act immediately:

| Signal | Type | Action |
|--------|------|--------|
| "No / wrong / that's not right / you did it again" | Correction | Three-step atomic op |
| Non-zero exit / script error | Failure | `mistake-log.md` entry |
| "I wish you could... / can you also..." | Feature request | `memory/feature-requests.md` |
| User provides info agent didn't know | Knowledge gap | GOOD entry in `bad-good-examples.md` |
| "I already told you this" | Recurrence | Check Recurrence-Count, potentially promote |
| BAD entry count hits 3 | Promotion threshold | Promote to iron rule (see references/) |

---

## Promotion Rule Overview

When a BAD pattern's `Recurrence-Count` reaches **3**, the error has proven it can't be fixed by logging alone — it needs to become an inescapable rule.

**Why 3?** Once is a mistake. Twice is a warning. Three times means the behavior is structurally encoded and needs structural intervention.

**Promotion action** (in same turn as detection):
1. Add a hardcoded checkpoint to the agent's main config file (e.g. `AGENTS.md`, `CLAUDE.md`, `.cursorrules`)
2. Bold-mark the entry in `CONTEXT.md` lessons section with `⚠️ IRON RULE`
3. Mark the BAD entry as promoted with date

Full protocol: [references/promotion-rules.md](references/promotion-rules.md)

---

## Path Convention

Each agent maintains its own data files. The `{WORKSPACE}` variable resolves per agent:

| File | Path |
|------|------|
| Mistake log | `{WORKSPACE}/memory/mistake-log.md` |
| Pattern library | `{WORKSPACE}/references/bad-good-examples.md` |
| Feature requests | `{WORKSPACE}/memory/feature-requests.md` |
| Hot memory | `{WORKSPACE}/CONTEXT.md` → lessons section |

**Default workspace**: `~/.openclaw/workspace` (set `--workspace` to your project root).

**For generic use**: default `{WORKSPACE}` to `.learnings/` in the project root if no workspace config exists.

---

## Weekly Review Protocol

Run every week (or on explicit review request):

1. Read `references/bad-good-examples.md` in full
2. For each BAD entry: did this pattern occur this week?
   - ✅ No → note "passed"
   - ❌ Yes → run three-step atomic op, increment Recurrence-Count
3. Check if any entry now has Recurrence-Count ≥ 3 → promote if so
4. Scan `memory/feature-requests.md` for pending items that can be advanced
5. Write weekly summary to `memory/YYYY-MM-DD.md`

---

## Cross-Agent / Multi-Agent Role

- When QC'ing a sub-agent output, check whether any known BAD patterns appear in the result
- If a sub-agent shows the same error type across multiple sessions, recommend iron-rule promotion in that agent's config file
- Monthly: tally agents with Recurrence-Count ≥ 3 entries, surface for batch iron-rule promotion
