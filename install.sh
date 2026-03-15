#!/bin/bash
# AI Skills installer — symlinks skills into each IDE

SKILLS_ROOT="$(cd "$(dirname "$0")" && pwd)"

link_skill() {
  local skill_path="$1"
  local target_dir="$2"
  local skill_name
  skill_name="$(basename "$skill_path")"

  mkdir -p "$target_dir"
  ln -sf "$skill_path" "$target_dir/$skill_name"
  echo "  linked $skill_name -> $target_dir"
}

SKILLS=(
  "$SKILLS_ROOT/workflow/code-review"
  "$SKILLS_ROOT/workflow/question-details"
  "$SKILLS_ROOT/workflow/requirements-plan-design-thinking"
  "$SKILLS_ROOT/backend/write-postgres-sql"
)

echo "==> Installing skills for Copilot"
for s in "${SKILLS[@]}"; do
  link_skill "$s" "$HOME/.copilot/skills"
done

echo "==> Installing skills for Cursor"
for s in "${SKILLS[@]}"; do
  link_skill "$s" "$HOME/.cursor/skills"
done

echo "==> Installing skills for Claude Code"
for s in "${SKILLS[@]}"; do
  link_skill "$s" "$HOME/.claude/skills"
done

echo "Done."
