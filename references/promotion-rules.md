# Promotion Rules: BAD Pattern → Iron Rule

> **Why have a threshold?** Logging is necessary but not sufficient for behavioral change. If a mistake recurs three or more times despite being logged, the mechanism of "record and remember" has demonstrably failed for that pattern. The only path forward is structural intervention: embedding the rule so deeply into the agent's operating context that it cannot be bypassed through the same cognitive shortcut that keeps triggering the mistake.

---

## Promotion Trigger

**Condition**: A BAD entry's `复发次数` (Recurrence-Count) reaches **3**.

**Why 3, not 2 or 5?**
- Once: any agent can make a mistake once. No pattern established.
- Twice: could be coincidence, similar context. A warning, not a verdict.
- Three times: the behavior is structurally encoded. The agent's "default path" reliably leads here. Logging won't fix default paths — only constraints will.
- Five: waiting longer means more user frustration and more wasted sessions between occurrences 3 and 5.

---

## Promotion Actions (all in the same session turn)

### Step 1: Write to your main Agent config file

The target is your primary behavioral config — whichever file your agent reads at the start of every session. This could be `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, or a similar always-loaded file.

Add a new hardcoded checkpoint with a `🔴` marker. Format:

```markdown
## 🔴 [Rule category] Iron Rule（promoted YYYY-MM-DD from BAD-{CODE}）

**触发**：[When does this rule activate — specific signal]
**规则**：[Exact rule — actionable enough that an agent reading this cold can comply]
**验证**：[How to confirm compliance — what to check before proceeding]
```

Place it in the appropriate section of the config file (or create a new section if none fits).

### Step 2: Update `CONTEXT.md` lessons section

Change the existing lessons line from:

```
- **[keyword]**: [one-line rule] (YYYY-MM-DD)
```

To:

```
- ⚠️ **IRON RULE — [keyword]**: [one-line rule] (YYYY-MM-DD → PROMOTED YYYY-MM-DD)
```

### Step 3: Mark the BAD entry as promoted

In `references/bad-good-examples.md`, update the entry's status line:

```markdown
**状态**：`→ 已升级为 iron rule（YYYY-MM-DD）`
```

---

## Post-Promotion Monitoring

After promotion, the BAD entry remains in `bad-good-examples.md`. It is **not removed**.

**Why keep it?**
- Promoted rules can still be violated if the config section isn't read carefully
- The entry serves as audit trail: when was this promoted, what triggered it
- If the iron rule itself is violated post-promotion, that's a meta-failure requiring escalation to the user

**Post-promotion violation**: If the iron rule is broken after promotion, log a new mistake entry with category `meta` and immediately surface to the user for review of the agent's operating context.

---

## Weekly Review Protocol

Run every week (or on explicit request):

```
1. Read references/bad-good-examples.md in full
2. For each BAD entry:
   a. Did this pattern occur this week?
      ✅ No  → add "week of YYYY-MM-DD: clean" comment (or just mental note)
      ❌ Yes → run three-step atomic op + increment Recurrence-Count
   b. Is Recurrence-Count now ≥ 3?
      → If yes: initiate promotion (steps above)
3. Scan memory/feature-requests.md for `pending` items:
   → Any that can be advanced this week? Assign or flag.
4. Write summary to memory/YYYY-MM-DD.md:
   - BAD entries checked: N
   - Violations found: N (list titles)
   - Promotions triggered: N (list BAD codes)
   - Feature requests reviewed: N
```

---

## Demotion (Rare)

If a promoted iron rule is later deemed overly restrictive or incorrect, it can be demoted back to a BAD entry. This requires:
1. Explicit user confirmation
2. Removal of the `🔴` block from the config file
3. Reverting the `CONTEXT.md` entry
4. Updating `bad-good-examples.md` status to `demoted (YYYY-MM-DD) — reason: [reason]`

Demotions should be rare. If a rule keeps getting demoted and re-promoted, that's a signal the underlying behavior trigger needs redesign, not just toggling.
