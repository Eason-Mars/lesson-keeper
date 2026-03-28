#!/usr/bin/env bash
# log-correction.sh — Self-Improvement Skill automation
# Writes a correction atomically to all three self-improvement data files,
# or records a feature request to memory/feature-requests.md + CONTEXT.md.
#
# Usage (correction — default):
#   bash log-correction.sh \
#     --workspace ~/.openclaw/workspace \
#     --title "Route bypass" \
#     --scene "Did X directly instead of routing to Phoenix" \
#     --error "Violated routing rule: code changes go to Phoenix" \
#     --cause "Thought it was 'just two lines'" \
#     --fix "Identified violation, routing correctly going forward" \
#     --category "BAD-R"
#
# Usage (feature-request):
#   bash log-correction.sh \
#     --type feature-request \
#     --workspace ~/.openclaw/workspace \
#     --title "Pathfinder 推送后自动发 DM 摘要" \
#     --need "每次 Pathfinder 完成推送后，自动发一条执行摘要到 DM" \
#     --scene "Eason 要在 DM 里直接看到推送结果，不用去群里找" \
#     --priority high \
#     --impl "Phoenix 🔥 在 Pathfinder pipeline 末尾增加 notify_dm() 步骤"
#
# --type options: correction (default) / feature-request
# --category options (correction only): BAD-R (routing) / BAD-Q (QC) / BAD-S (system) /
#                     BAD-C (communication) / BAD-D (data) /
#                     BAD-A (sub-agent lookup) / BAD-L (LLM arch) /
#                     BAD-T (timing) / or any custom BAD-X

set -euo pipefail

# ── Argument parsing ──────────────────────────────────────────────────────────
TYPE="correction"
WORKSPACE=""
TITLE=""
SCENE=""
ERROR=""
CAUSE=""
FIX=""
CATEGORY=""
NEED=""
PRIORITY=""
IMPL=""
FACT=""
SOURCE="conversation"
CONTEXT_ARG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)      TYPE="$2";        shift 2 ;;
    --workspace) WORKSPACE="$2";   shift 2 ;;
    --title)     TITLE="$2";       shift 2 ;;
    --scene)     SCENE="$2";       shift 2 ;;
    --error)     ERROR="$2";       shift 2 ;;
    --cause)     CAUSE="$2";       shift 2 ;;
    --fix)       FIX="$2";         shift 2 ;;
    --category)  CATEGORY="$2";    shift 2 ;;
    --need)      NEED="$2";        shift 2 ;;
    --priority)  PRIORITY="$2";    shift 2 ;;
    --impl)      IMPL="$2";        shift 2 ;;
    --fact)      FACT="$2";        shift 2 ;;
    --source)    SOURCE="$2";      shift 2 ;;
    --context)   CONTEXT_ARG="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

# ── Validation ────────────────────────────────────────────────────────────────
missing=()
[[ -z "$WORKSPACE" ]] && missing+=("--workspace")
[[ -z "$TITLE" ]]     && missing+=("--title")

if [[ "$TYPE" == "correction" ]]; then
  [[ -z "$SCENE" ]]     && missing+=("--scene")
  [[ -z "$ERROR" ]]     && missing+=("--error")
  [[ -z "$CAUSE" ]]     && missing+=("--cause")
  [[ -z "$FIX" ]]       && missing+=("--fix")
  [[ -z "$CATEGORY" ]]  && missing+=("--category")
elif [[ "$TYPE" == "feature-request" ]]; then
  [[ -z "$NEED" ]]      && missing+=("--need")
  [[ -z "$SCENE" ]]     && missing+=("--scene")
  [[ -z "$PRIORITY" ]]  && missing+=("--priority")
  [[ -z "$IMPL" ]]      && missing+=("--impl")
elif [[ "$TYPE" == "error" ]]; then
  [[ -z "$ERROR" ]]       && missing+=("--error")
  [[ -z "$CONTEXT_ARG" ]] && missing+=("--context")
elif [[ "$TYPE" == "knowledge" ]]; then
  [[ -z "$FACT" ]]  && missing+=("--fact")
else
  echo "❌ Unknown --type: $TYPE (valid: correction, feature-request, error, knowledge)" >&2
  exit 1
fi

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "❌ Missing required arguments: ${missing[*]}" >&2
  echo "   Run with --help or see SKILL.md for usage." >&2
  exit 1
fi

WORKSPACE="${WORKSPACE%/}"  # strip trailing slash
DATE=$(date +%Y-%m-%d)
DATETIME=$(date "+%Y-%m-%d %H:%M")

# ── File paths ────────────────────────────────────────────────────────────────
MISTAKE_LOG="$WORKSPACE/memory/mistake-log.md"
CONTEXT_FILE="$WORKSPACE/CONTEXT.md"
BAD_GOOD_FILE="$WORKSPACE/references/bad-good-examples.md"
FEAT_REQ_FILE="$WORKSPACE/memory/feature-requests.md"

# ══════════════════════════════════════════════════════════════════════════════
# BRANCH: feature-request
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$TYPE" == "feature-request" ]]; then

  # ── Bootstrap ──────────────────────────────────────────────────────────────
  mkdir -p "$WORKSPACE/memory"

  if [[ ! -f "$FEAT_REQ_FILE" ]]; then
    cat > "$FEAT_REQ_FILE" <<'EOF'
# Feature Requests

_功能需求记录。通过 log-correction.sh --type feature-request 自动写入。_
_格式：FEAT-YYYYMMDD + 标题 / 需求 / 场景 / 优先级 / 状态 / 实现建议_

EOF
    echo "📄 Created: $FEAT_REQ_FILE"
  fi

  if [[ ! -f "$CONTEXT_FILE" ]]; then
    cat > "$CONTEXT_FILE" <<'EOF'
# CONTEXT.md

## 📌 待办

EOF
    echo "📄 Created: $CONTEXT_FILE"
  fi

  # ── Step 1: Append to feature-requests.md ──────────────────────────────────
  FEAT_ID="FEAT-$(date +%Y%m%d)"

  cat >> "$FEAT_REQ_FILE" <<EOF

## [$FEAT_ID] $TITLE

**日期**：$DATE
**来源**：对话记录
**需求**：$NEED
**场景**：$SCENE
**优先级**：$PRIORITY
**状态**：pending
**实现建议**：$IMPL
EOF

  echo "✅ Step 1: Appended to $FEAT_REQ_FILE"

  # ── Step 2: Append to CONTEXT.md 📌 待办 section ───────────────────────────
  TODO_LINE="- 📋 [FEAT] $TITLE（$DATE，pending）"

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

  echo "✅ Step 2: Appended to 📌 待办 in $CONTEXT_FILE"

  # ── Done ───────────────────────────────────────────────────────────────────
  echo ""
  echo "🎯 Feature request recorded: \"$TITLE\""
  echo "   feature-requests.md → $FEAT_REQ_FILE"
  echo "   CONTEXT.md (待办)   → $CONTEXT_FILE"
  exit 0
fi

# ══════════════════════════════════════════════════════════════════════════════
# BRANCH: error
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$TYPE" == "error" ]]; then

  # ── Bootstrap ──────────────────────────────────────────────────────────────
  mkdir -p "$WORKSPACE/memory"

  ERRORS_FILE="$WORKSPACE/memory/errors.md"

  if [[ ! -f "$ERRORS_FILE" ]]; then
    cat > "$ERRORS_FILE" <<'EOF'
# Errors

_执行错误记录。通过 log-correction.sh --type error 自动写入。_
_格式：ERR-YYYYMMDD + 标题 / 错误 / 上下文 / 状态_

EOF
    echo "📄 Created: $ERRORS_FILE"
  fi

  # ── Append to errors.md ────────────────────────────────────────────────────
  ERR_ID="ERR-$(date +%Y%m%d)"

  cat >> "$ERRORS_FILE" <<EOF

## [$ERR_ID] $TITLE

**日期**：$DATE
**错误**：$ERROR
**上下文**：$CONTEXT_ARG
**状态**：pending
EOF

  echo "✅ Appended to $ERRORS_FILE"
  echo ""
  echo "🎯 Error recorded: \"$TITLE\""
  echo "   errors.md → $ERRORS_FILE"
  exit 0
fi

# ══════════════════════════════════════════════════════════════════════════════
# BRANCH: knowledge
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$TYPE" == "knowledge" ]]; then

  # ── Bootstrap ──────────────────────────────────────────────────────────────
  mkdir -p "$WORKSPACE/memory"

  LEARNINGS_FILE="$WORKSPACE/memory/learnings.md"

  if [[ ! -f "$LEARNINGS_FILE" ]]; then
    cat > "$LEARNINGS_FILE" <<'EOF'
# Learnings

_新事实/知识更新记录。通过 log-correction.sh --type knowledge 自动写入。_
_格式：LRN-YYYYMMDD + 标题 / 事实 / 来源 / 状态_

EOF
    echo "📄 Created: $LEARNINGS_FILE"
  fi

  # ── Append to learnings.md ─────────────────────────────────────────────────
  LRN_ID="LRN-$(date +%Y%m%d)"

  cat >> "$LEARNINGS_FILE" <<EOF

## [$LRN_ID] $TITLE

**日期**：$DATE
**事实**：$FACT
**来源**：$SOURCE
**状态**：active
EOF

  echo "✅ Appended to $LEARNINGS_FILE"
  echo ""
  echo "🎯 Knowledge recorded: \"$TITLE\""
  echo "   learnings.md → $LEARNINGS_FILE"
  exit 0
fi

# ══════════════════════════════════════════════════════════════════════════════
# BRANCH: correction (original three-step flow)
# ══════════════════════════════════════════════════════════════════════════════

# ── Bootstrap missing files ───────────────────────────────────────────────────
mkdir -p "$WORKSPACE/memory" "$WORKSPACE/references"

if [[ ! -f "$MISTAKE_LOG" ]]; then
  cat > "$MISTAKE_LOG" <<'EOF'
# Mistake Log

_Entries are added automatically via the self-improvement skill._
_Each entry: date, scene, error, root cause, fix, prevention, category._

EOF
  echo "📄 Created: $MISTAKE_LOG"
fi

if [[ ! -f "$CONTEXT_FILE" ]]; then
  cat > "$CONTEXT_FILE" <<'EOF'
# CONTEXT.md

## 🧠 教训

EOF
  echo "📄 Created: $CONTEXT_FILE"
fi

if [[ ! -f "$BAD_GOOD_FILE" ]]; then
  cat > "$BAD_GOOD_FILE" <<'EOF'
# BAD / GOOD Examples

_Entries are added via the self-improvement skill._
_Format: BAD-XX header (scene/issue/recurrence) + GOOD-XX header (correct behavior)._

EOF
  echo "📄 Created: $BAD_GOOD_FILE"
fi

# ── Step 1: Append to mistake-log.md ─────────────────────────────────────────
echo "" >> "$MISTAKE_LOG"
cat >> "$MISTAKE_LOG" <<EOF
## $DATE | $TITLE

**场景 (Scene)**：$SCENE
**错误 (Error)**：$ERROR
**根因 (Root cause)**：$CAUSE
**修复 (Fix applied)**：$FIX
**分类 (Category)**：\`$CATEGORY\`
**状态 (Status)**：待观察
EOF

echo "✅ Step 1: Appended to $MISTAKE_LOG"

# ── Step 2: Append lesson to CONTEXT.md ──────────────────────────────────────
# Try to insert into 🧠 教训 section; if not found, append at end.
LESSON_LINE="- **[$TITLE]**：$CAUSE → $FIX ($DATE)"

if grep -q "🧠 教训" "$CONTEXT_FILE" 2>/dev/null; then
  # Insert after the 🧠 教训 heading
  # Use awk to insert after the matching line
  awk -v line="$LESSON_LINE" '
    /🧠 教训/ { print; found=1; next }
    found && /^$/ { print line; found=0 }
    { print }
  ' "$CONTEXT_FILE" > "${CONTEXT_FILE}.tmp" && mv "${CONTEXT_FILE}.tmp" "$CONTEXT_FILE"
else
  # Append a new section
  printf "\n## 🧠 教训\n\n%s\n" "$LESSON_LINE" >> "$CONTEXT_FILE"
fi

echo "✅ Step 2: Appended lesson to $CONTEXT_FILE"

# ── Step 3: Update or append bad-good-examples.md ────────────────────────────
# Check if a BAD entry with this category exists — look for matching title
# Strategy: search for "BAD-{CATEGORY_CODE}" + title proximity
CATEGORY_CODE="${CATEGORY#BAD-}"  # e.g. "R" from "BAD-R"

# Check if an entry with the same title already exists
if grep -qF "**$TITLE**" "$BAD_GOOD_FILE" 2>/dev/null || \
   grep -qF "：$TITLE" "$BAD_GOOD_FILE" 2>/dev/null; then
  # Entry exists — update Recurrence-Count and 最近日期
  python3 - "$BAD_GOOD_FILE" "$TITLE" "$DATE" <<'PYEOF'
import sys, re

filepath = sys.argv[1]
title = sys.argv[2]
date = sys.argv[3]

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Find the BAD block containing this title
# Increment 复发次数 count and update 最近日期
lines = content.split('\n')
in_block = False
updated = False

for i, line in enumerate(lines):
    if title in line and ('BAD' in line or '❌' in line):
        in_block = True
    if in_block:
        # Update 复发次数
        m = re.match(r'(\*\*复发次数\*\*：)(\d+)(次.*)', line)
        if m:
            new_count = int(m.group(2)) + 1
            # Append date to the parenthetical list
            rest = m.group(3)
            if '（' in rest and '）' in rest:
                rest = rest.rstrip('）') + ' / ' + date + '）'
            else:
                rest = f'次（{date}）'
            lines[i] = f'{m.group(1)}{new_count}{rest}'
            updated = True
        # Update 最近日期
        if re.match(r'\*\*最近日期\*\*：', line):
            lines[i] = f'**最近日期**：{date}'
        # Stop at next BAD/GOOD header
        if i > 0 and (line.startswith('### ') or line.startswith('---')) and updated:
            break

with open(filepath, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))

if updated:
    print(f"Updated Recurrence-Count for: {title}")
else:
    print(f"WARNING: Could not auto-update count for: {title}. Please update manually.")
PYEOF
  echo "✅ Step 3: Updated Recurrence-Count in $BAD_GOOD_FILE"
else
  # New entry — determine next number for this category
  # Count only header lines (### ❌ BAD-Xn); strip newlines to ensure single numeric value
  EXISTING_COUNT=$(grep -c "### ❌ ${CATEGORY}" "$BAD_GOOD_FILE" 2>/dev/null | tr -d '\n' | head -1 || true)
  EXISTING_COUNT=${EXISTING_COUNT:-0}
  NEXT_N=$((EXISTING_COUNT + 1))
  ENTRY_ID="${CATEGORY}${NEXT_N}"

  echo "" >> "$BAD_GOOD_FILE"
  cat >> "$BAD_GOOD_FILE" <<EOF

### ❌ ${ENTRY_ID}：${TITLE}

**場景**：${SCENE}
**問題**：${ERROR}
**根因**：${CAUSE}
**复发次数**：1次（${DATE}）
**最近日期**：${DATE}
**状态**：active

---

### ✅ GOOD-${CATEGORY_CODE}${NEXT_N}：${TITLE}（正确做法）

**正确做法**：${FIX}
**检查触发器**：[Fill in: what signal should recall this GOOD entry]
EOF

  echo "✅ Step 3: Added new BAD/GOOD entry [$ENTRY_ID] to $BAD_GOOD_FILE"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "🎯 All three steps complete for: \"$TITLE\""
echo "   mistake-log   → $MISTAKE_LOG"
echo "   CONTEXT.md    → $CONTEXT_FILE"
echo "   bad-good-exs  → $BAD_GOOD_FILE"
echo ""
echo "⚠️  Check Recurrence-Count in bad-good-examples.md."
echo "   If count ≥ 3, run promotion protocol (see references/promotion-rules.md)."
