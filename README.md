# lesson-keeper

> Stop re-learning the same lessons. Turn corrections into permanent behavioral change.
> 让每一次纠正都永久生效——不再重蹈覆辙。

---

## What it does / 功能介绍

Most AI agents forget corrections between sessions. You correct a mistake, the agent acknowledges it, and then repeats the same error next week. **lesson-keeper** solves this with three mechanisms:

1. **Atomic three-place write** — every correction is written to three files simultaneously: a detailed mistake log, a hot-memory context file (read every session), and a pattern library that tracks recurrence.

2. **Recurrence detection** — every BAD entry has a `Recurrence-Count`. If the same mistake happens three times, the pattern library automatically flags it for promotion.

3. **Iron rule promotion** — when `Recurrence-Count ≥ 3`, the error gets promoted into the agent's main config file as an inescapable rule with a verifiable enforcement command, not just a note. Structural problems require structural solutions.

<details>
<summary>📖 中文说明</summary>

大多数 AI Agent 在会话之间会忘记纠正。你纠正了一个错误，Agent 当场承认，但下周又重蹈覆辙。**lesson-keeper** 通过三个机制解决这个问题：

1. **三步原子写入** — 每次纠正同时写入三个文件：详细错误日志、每次会话必读的热记忆文件、以及追踪复发的模式库。
2. **复发检测** — 每个 BAD 条目都有 `Recurrence-Count`。同一错误发生三次，模式库自动标记晋升。
3. **铁律晋升** — 当 `Recurrence-Count ≥ 3` 时，错误被晋升为 Agent 主配置文件中不可绕过的铁律，附带可执行的验证命令。结构性问题需要结构性干预。

</details>

---

## Why lesson-keeper / 为什么选 lesson-keeper

### Enforcement, not suggestions

Most self-improvement skills suggest recording corrections. lesson-keeper **enforces** it: the three-place atomic write is mandatory, not optional. Partial logging is explicitly called out as "not fixed." The script (`log-correction.sh`) executes all three writes in a single command so nothing can be forgotten.

### Built specifically for OpenClaw

lesson-keeper is not a generic skill ported to OpenClaw — it was designed from the ground up for the OpenClaw workspace file structure. The script writes directly to `{WORKSPACE}/memory/`, `{WORKSPACE}/CONTEXT.md`, and `{WORKSPACE}/references/bad-good-examples.md` — the exact paths OpenClaw agents read every session. No adapter layer. No manual path configuration.

### Automatic promotion with verifiable enforcement commands

When a mistake recurs 3 times, lesson-keeper doesn't just add a note — it writes a `🔴` iron rule block into your primary agent config file (`AGENTS.md`, `CLAUDE.md`, `.cursorrules`, etc.) with three fields: trigger, rule, and a **verifiable enforcement command** that can be run to confirm compliance. This is the only skill that closes the loop from "mistake logged" to "behaviorally unreachable."

### Includes a trigger evaluation tool (OpenClaw-native)

lesson-keeper ships with `run_eval_openclaw.py`, the only OpenClaw-compatible trigger testing tool bundled with a skill. It lets you test whether the skill description actually causes the agent to activate for the right queries — not just assume it does. Validated across 3 rounds of iteration: **17/17 assertions + 20/20 trigger tests**.

<details>
<summary>📖 中文说明</summary>

### 强制执行，不是建议

大多数 self-improvement Skill 是「建议记录纠正」。lesson-keeper **强制执行**：三步原子写入是必须的，不是可选的。脚本 `log-correction.sh` 一条命令完成所有三步写入，不存在遗漏的可能。

### OpenClaw 专属，不是通用版移植

lesson-keeper 从一开始就为 OpenClaw 工作区文件结构设计。脚本直接写入 `{WORKSPACE}/memory/`、`{WORKSPACE}/CONTEXT.md`、`{WORKSPACE}/references/bad-good-examples.md`——正是 OpenClaw Agent 每次会话必读的路径。无需适配层，无需手动配置路径。

### 自动晋升 + 可执行验证命令

错误复发 3 次时，lesson-keeper 不只是加一条注释——它将 `🔴` 铁律块写入你的主配置文件（`AGENTS.md` / `CLAUDE.md` / `.cursorrules` 等），包含触发条件、规则内容和**可执行验证命令**。这是唯一能从「已记录」到「行为上不可绕过」形成闭环的 Skill。

### 附带触发评测工具（OpenClaw 原生）

lesson-keeper 内置 `run_eval_openclaw.py`——唯一随 Skill 附带 OpenClaw 兼容触发测试工具。可验证 Skill description 是否真的让 Agent 在正确场景下触发，而不是假设能用。经过3轮迭代验证：17/17 assertions 全部通过 + 触发测试 20/20。

</details>

---

## Installation / 安装

```bash
# Via ClawHub
npx clawhub@latest install lesson-keeper

# Manual
git clone https://github.com/YOUR_GITHUB_USERNAME/lesson-keeper \
  ~/.openclaw/workspace/.agents/skills/lesson-keeper
```

<details>
<summary>📖 中文说明</summary>

通过 ClawHub 一行安装，或 git clone 到指定路径。安装后无需额外配置，脚本会自动在 `--workspace` 路径下创建所需文件。

</details>

---

## Quick Start / 快速上手

When your agent is corrected, run:

```bash
bash ~/.openclaw/workspace/.agents/skills/lesson-keeper/scripts/log-correction.sh \
  --workspace ~/.openclaw/workspace \
  --title "Skipped routing step" \
  --scene "Handled task directly instead of routing to the right agent" \
  --error "Violated routing rule for task type X" \
  --cause "Assumed it was too small to route" \
  --fix "Route correctly going forward regardless of perceived size" \
  --category "routing"
```

This writes atomically to:
- `memory/mistake-log.md` — full context record
- `CONTEXT.md` — hot memory (read every session)
- `references/bad-good-examples.md` — pattern tracker with Recurrence-Count

<details>
<summary>📖 中文说明</summary>

Agent 被纠正时，执行上面的命令。脚本会原子写入三个文件。所有参数都是必填项——这是有意为之的设计，防止字段被省略导致模式匹配失效。

</details>

---

## The four log types / 四种记录类型

| Type | When to use | Flag |
|------|-------------|------|
| `correction` (default) | Agent made a mistake, user corrected it | `--type correction` |
| `feature-request` | User voiced a missing capability | `--type feature-request` |
| `error` | A command/script failed (non-zero exit) | `--type error` |
| `knowledge` | Agent learned a new fact or updated understanding | `--type knowledge` |

Each type writes to the appropriate file(s) in `{WORKSPACE}/memory/`.

<details>
<summary>📖 中文说明</summary>

四种记录类型各对应不同场景：
- **correction**：被纠正时的标准三步原子写入
- **feature-request**：写入 `feature-requests.md` + 在 `CONTEXT.md` 留痕，确保需求跨会话存活
- **error**：脚本执行失败的错误记录
- **knowledge**：新知识/事实更新，写入 `learnings.md`

</details>

---

## How promotion works / 自动晋升机制

When any BAD pattern's `Recurrence-Count` reaches **3**:

1. A `🔴` iron rule block is added to your main agent config file (e.g. `AGENTS.md`, `CLAUDE.md`, `.cursorrules`) with three fields: **trigger**, **rule**, and a **verification command**
2. The `CONTEXT.md` entry is marked `⚠️ IRON RULE`
3. The BAD entry in `bad-good-examples.md` is marked as promoted

**Why 3?** Once is a mistake. Twice is a warning. Three times means the behavior is structurally encoded — logging alone won't fix it. Only embedding it as a rule in the always-read config creates the structural intervention needed.

See [`references/promotion-rules.md`](references/promotion-rules.md) for the full protocol.

<details>
<summary>📖 中文说明</summary>

当某个 BAD 模式的 `Recurrence-Count` 达到 **3** 时，自动触发晋升流程：
1. 在主配置文件（`AGENTS.md` 等）写入 `🔴` 铁律块，包含触发条件、规则内容、**可执行验证命令**
2. `CONTEXT.md` 对应条目标记为 `⚠️ IRON RULE`
3. `bad-good-examples.md` 中的 BAD 条目标记为已晋升

**为什么是 3 次？** 一次是失误，两次是警告，三次意味着行为已经结构化编码。只有在每次必读的配置文件里嵌入铁律，才能创造结构性干预。

</details>

---

## Eval tools / 评测工具（OpenClaw 专属）

This skill ships with a complete automated eval + improvement loop.

### Run a single eval pass

```bash
python3 scripts/grade_eval.py evals/evals.json
```

Checks all assertions across the 3 built-in eval scenarios and outputs a pass/fail report + `evals/grading.json`.

### Run trigger evaluation

Tests whether the skill description causes the agent to trigger for the right queries:

```bash
python3 scripts/run_eval_openclaw.py \
  --eval-set evals/trigger-eval-set.json \
  --skill-path . \
  --verbose
```

### Run the improvement loop

Iteratively improves the skill description using Claude, evaluating against a held-out test set:

```bash
python3 scripts/run_loop_openclaw.py \
  --eval-set evals/trigger-eval-set.json \
  --skill-path . \
  --model claude-opus-4-5 \
  --max-iterations 5 \
  --runs-per-query 3 \
  --verbose \
  --results-dir lesson-keeper-workspace/loop-results
```

The loop outputs the best description found across all iterations, with train/test split tracking to prevent overfitting.

<details>
<summary>📖 中文说明</summary>

lesson-keeper 是唯一附带 OpenClaw 兼容触发评测工具的 Skill。`run_eval_openclaw.py` 可测试 Skill description 是否在正确场景下触发，`run_loop_openclaw.py` 可自动迭代优化 description 并防止过拟合。经过3轮迭代验证，最终达到 17/17 assertions（100%）+ 触发测试 20/20。

</details>

---

## File layout

```
lesson-keeper/
├── SKILL.md                        # Skill entrypoint (loaded by OpenClaw)
├── README.md                       # This file
├── references/
│   ├── logging-formats.md          # Entry format specs for all log types
│   └── promotion-rules.md          # Iron rule promotion protocol
├── scripts/
│   ├── log-correction.sh           # Atomic three-step writer (main tool)
│   ├── grade_eval.py               # Assertion-based eval grader
│   ├── run_eval_openclaw.py        # Trigger evaluation runner
│   └── run_loop_openclaw.py        # Eval + description improvement loop
└── evals/
    └── evals.json                  # 3 built-in eval scenarios
```

---

## Credits / 致谢

Inspired by self-improving-agent by @pskoett on ClawHub.
Built with deeper OpenClaw integration, atomic enforcement, and verified test coverage.

---

## License

MIT
