# Logging Formats Reference

> Why have a spec? Because ambiguous formats cause agents to skip fields ("I'll fill that in later") or write entries that don't enable pattern matching. Structured, consistent entries make it possible to compare across time, detect recurrence, and run automated Recurrence-Count updates.

---

## 1. `memory/mistake-log.md` Entry Format

```markdown
## YYYY-MM-DD | {Title}

**场景 (Scene)**：[What was happening when the mistake occurred — context, not just facts]
**错误 (Error)**：[Exactly what was done wrong — specific behavior, not vague "did X poorly"]
**违反规则 (Rule violated)**：[Which rule/principle was broken, if named]
**根因 (Root cause)**：[Why this happened — cognitive shortcut taken, missing check, wrong assumption]
**修复 (Fix applied)**：[What was done in this session to correct it]
**防重犯 (Prevention)**：[Concrete behavioral change for next time — actionable, not "be more careful"]
**状态 (Status)**：`待观察` | `已修复` | `反复出现`
**分类 (Category)**：[category label, e.g. `routing` / `quality-check` / `data-source` / `communication` / `timing`]
```

### Why each field matters

- **Scene**: Without context, the log entry looks like an abstract rule violation. Context makes it retrievable and comparable.
- **Root cause**: The most important field. "I forgot" is not a root cause. "I assumed X without verifying" is.
- **Prevention**: Must be behavioral and specific. "Check routing table before acting" > "route correctly".
- **Category**: Enables filtering by type, which is how Recurrence-Count works across entries.

---

## 2. `references/bad-good-examples.md` Entry Format

Entries come in BAD/GOOD pairs. The BAD entry is the pattern; the GOOD entry is the corrective behavior.

```markdown
### ❌ BAD-{CATEGORY}-{N}：{Title}

**场景**：[When does this mistake typically occur]
**问题**：[Why this behavior is harmful — consequences, not just rule statement]
**复发次数**：{N}次（YYYY-MM-DD / YYYY-MM-DD / ...）
**最近日期**：YYYY-MM-DD
**状态**：`active` | `→ 已升级为 iron rule（YYYY-MM-DD）`

---

### ✅ GOOD-{CATEGORY}-{N}：{Corresponding correct title}

**正确做法**：[Exact steps or behavior — specific enough to execute without interpretation]
**检查触发器**：[What signal should cause the agent to recall this GOOD entry]
```

### Category labels (suggested)

| Label | Domain |
|-------|--------|
| `routing` | Routing / dispatch decisions |
| `quality-check` | QC / output validation |
| `system` | System / infrastructure |
| `communication` | Reporting / communication style |
| `data-source` | Data accuracy / source verification |
| `agent-lookup` | Sub-agent capability lookup |
| `llm-arch` | LLM call architecture |
| `timing` | Timing / scheduling |

New categories: add a new label, document it in this file.

### Recurrence-Count update rule

Each time a BAD pattern recurs:
1. Increment the count in `复发次数`
2. Append the new date to the parenthetical list
3. Update `最近日期`
4. If count ≥ 3: initiate promotion (see `promotion-rules.md`)

---

## 3. `memory/feature-requests.md` Entry Format

```markdown
## [FEAT-YYYYMMDD] {Feature name}

**日期**：YYYY-MM-DD
**来源**：{Source — "user DM" / "team channel" / "agent self-identified"}
**需求**：[What the user wants to be able to do]
**场景**：[When/why they need it — the job to be done]
**优先级**：`high` | `medium` | `low`
**状态**：`pending` | `in_progress` | `done` | `wont-do`
**实现建议**：[How it could be built, who should own it]
```

### Why log feature requests here

Feature requests voiced in conversation evaporate. Logging them creates a backlog that can be reviewed weekly, prioritized, and assigned — rather than discovered again six weeks later when the user repeats themselves.
