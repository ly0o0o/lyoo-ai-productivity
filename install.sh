#!/bin/bash
# AI Skills 安装脚本
# 将所有 skills 以 symlink 方式链接到各 IDE 的 skills 目录
# 用法：chmod +x install.sh && ./install.sh

SKILLS_ROOT="$(cd "$(dirname "$0")" && pwd)"

link_skill() {
  local skill_path="$1"
  local target_dir="$2"
  local skill_name
  skill_name="$(basename "$skill_path")"

  mkdir -p "$target_dir"
  ln -sf "$skill_path" "$target_dir/$skill_name"
  echo "    ✓ $skill_name"
}

# 所有 skills 列表
SKILLS=(
  "$SKILLS_ROOT/workflow/code-review"
  "$SKILLS_ROOT/workflow/question-details"
  "$SKILLS_ROOT/workflow/requirements-plan-design-thinking"
  "$SKILLS_ROOT/backend/write-postgres-sql"
  "$SKILLS_ROOT/design/ui-ux-pro-max"
)

# IDE skills 目录映射
declare -A IDE_DIRS=(
  ["GitHub Copilot"]="$HOME/.copilot/skills"
  ["Cursor"]="$HOME/.cursor/skills"
  ["Claude Code"]="$HOME/.claude/skills"
  ["Kiro"]="$HOME/.kiro/skills"
  ["Codex CLI"]="$HOME/.codex/skills"
)

for ide in "GitHub Copilot" "Cursor" "Claude Code" "Kiro" "Codex CLI"; do
  target="${IDE_DIRS[$ide]}"
  echo ""
  echo "==> $ide  ($target)"
  for s in "${SKILLS[@]}"; do
    link_skill "$s" "$target"
  done
done

echo ""
echo "✅ 全部安装完成。"
echo ""
echo "验证安装："
echo "  ls -la ~/.copilot/skills/"
echo "  ls -la ~/.cursor/skills/"
echo "  ls -la ~/.claude/skills/"
echo "  ls -la ~/.kiro/skills/"
echo "  ls -la ~/.codex/skills/"
