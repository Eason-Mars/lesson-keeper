#!/usr/bin/env bash
# log-review.sh — Task Reviewer 主动复盘脚本
# 任务完成后主动复盘，原子写入 task-reviews.md（始终）和 CONTEXT.md 待办区块（仅有 improvement 时）。
#
# Usage:
#   bash log-review.sh \
#     --workspace /path/to/workspace \
#     --task "任务标题" \
#     --what-done "完成了什么" \
#     --how-long "耗时" \
#     --what-worked "做得好的地方" \
#     --improvement "可改进的地方（可选，有才填）" \
#     --skills-used "用到了哪些Skill（可选）"
#
# 写入逻辑：
#   - 始终写入 {WORKSPACE}/memory/task-reviews.md（全量复盘日志，append）
#   - 仅当有 --improvement 时，写入 {WORKSPACE}/CONTEXT.md 的 📌 待办 区块
#   - 升级机制：检查 task-reviews.md 中是否有 improvement 同类问题出现 ≥2 次
#             如果有，输出警告「建议升级到 lesson-keeper 三步原子操作」

set -euo pipefail

# ── Argument parsing ──────────────────────────────────────────────────────────
WORKSPACE=""
TASK=""
WHAT_DONE=""
HOW_LONG=""
WHAT_WORKED=""
IMPROVEMENT=""
SKILLS_USED=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace)   WORKSPACE="$2";   shift 2 ;;
    --task)        TASK="$2";        shift 2 ;;
    --what-done)   WHAT_DONE="$2";   shift 2 ;;
    --how-long)    HOW_LONG="$2";    shift 2 ;;
    --what-worked) WHAT_WORKED="$2"; shift 2 ;;
    --improvement) IMPROVEMENT="$2"; shift 2 ;;
    --skills-used) SKILLS_USED="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

# ── Validation ────────────────────────────────────────────────────────────────
missing=()
[[ -z "$WORKSPACE" ]]   && missing+=("--workspace")
[[ -z "$TASK" ]]        && missing+=("--task")
[[ -z "$WHAT_DONE" ]]   && missing+=("--what-done")
[[ -z "$HOW_LONG" ]]    && missing+=("--how-long")
[[ -z "$WHAT_WORKED" ]] && missing+=("--what-worked")

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "❌ Missing required arguments: ${missing[*]}" >&2
  echo "   Run with --help or see SKILL.md for usage." >&2
  exit 1
fi

WORKSPACE="${WORKSPACE%/}"  # strip trailing slash
DATETIME=$(date "+%Y-%m-%d %H:%M")

# ── File paths ────────────────────────────────────────────────────────────────
REVIEWS_FILE="$WORKSPACE/memory/task-reviews.md"
CONTEXT_FILE="$WORKSPACE/CONTEXT.md"

# ── Bootstrap ─────────────────────────────────────────────────────────────────
mkdir -p "$WORKSPACE/memory"

if [[ ! -f "$REVIEWS_FILE" ]]; then
  cat > "$REVIEWS_FILE" <<'EOF'
# Task Reviews Log

> 每次多步任务完成后由 log-review.sh 自动写入。
> 用途：主动复盘 + 发现重复改进点时自动升级到 lesson-keeper。

---
EOF
  echo "📄 Created: $REVIEWS_FILE"
fi

# ── Step 1: Append to task-reviews.md (always) ───────────────────────────────
{
  echo ""
  echo "## [$DATETIME] $TASK"
  echo "- **完成内容**：$WHAT_DONE"
  echo "- **耗时**：$HOW_LONG"
  echo "- **做得好**：$WHAT_WORKED"
  if [[ -n "$IMPROVEMENT" ]]; then
    echo "- **改进点**：$IMPROVEMENT"
  fi
  if [[ -n "$SKILLS_USED" ]]; then
    echo "- **使用Skill**：$SKILLS_USED"
  fi
  echo "---"
} >> "$REVIEWS_FILE"

echo "✅ Step 1: Appended to $REVIEWS_FILE"

# ── Step 2: Append to CONTEXT.md 📌 待办 section (only if improvement) ───────
if [[ -n "$IMPROVEMENT" ]]; then
  if [[ ! -f "$CONTEXT_FILE" ]]; then
    cat > "$CONTEXT_FILE" <<'EOF'
# CONTEXT.md

## 📌 待办

EOF
    echo "📄 Created: $CONTEXT_FILE"
  fi

  TODO_LINE="- 📋 [REVIEW] $TASK → 改进点：$IMPROVEMENT（$DATETIME）"

  if grep -q "📌 待办" "$CONTEXT_FILE" 2>/dev/null; then
    # Insert after the 📌 待办 heading (after its blank line)
    awk -v line="$TODO_LINE" '
      /📌 待办/ { print; found=1; next }
      found && /^$/ { print line; found=0 }
      { print }
    ' "$CONTEXT_FILE" > "${CONTEXT_FILE}.tmp" && mv "${CONTEXT_FILE}.tmp" "$CONTEXT_FILE"
  else
    # Append a new 📌 待办 section at end of file
    printf "\n## 📌 待办\n\n%s\n" "$TODO_LINE" >> "$CONTEXT_FILE"
  fi

  echo "✅ Step 2: Appended improvement to 📌 待办 in $CONTEXT_FILE"
else
  echo "ℹ️  Step 2: Skipped (no --improvement provided, CONTEXT.md unchanged)"
fi

# ── Step 3: Upgrade check — same improvement keyword ≥2 times ────────────────
if [[ -n "$IMPROVEMENT" ]]; then
  # Extract first 20 chars as a "keyword" to search for similar improvements
  IMP_KEYWORD="${IMPROVEMENT:0:20}"

  # Count how many past entries have similar improvement text
  SIMILAR_COUNT=$(grep -c "改进点.*${IMP_KEYWORD:0:10}" "$REVIEWS_FILE" 2>/dev/null || true)

  if [[ "$SIMILAR_COUNT" -ge 2 ]]; then
    echo ""
    echo "⚠️  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  升级警告：发现类似改进点 ≥2 次："
    echo "⚠️  关键词「${IMP_KEYWORD}」已在 task-reviews.md 出现 ${SIMILAR_COUNT} 次"
    echo "⚠️  建议升级到 lesson-keeper 三步原子操作！"
    echo "⚠️  运行：bash log-correction.sh --workspace $WORKSPACE \\"
    echo "⚠️    --title \"[任务名]\" --scene \"...\" --error \"...\" \\"
    echo "⚠️    --cause \"...\" --fix \"...\" --category \"BAD-X\""
    echo "⚠️  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  fi
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "🎯 Task review complete: \"$TASK\""
echo "   task-reviews.md → $REVIEWS_FILE"
if [[ -n "$IMPROVEMENT" ]]; then
  echo "   CONTEXT.md (待办) → $CONTEXT_FILE"
fi
