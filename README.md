# lyoo-ai-productivity

Single source of truth for AI agent skills. One repo, all IDEs.

## Structure

```
├── AGENTS.md                          # skill router for AI agents
├── install.sh                         # symlink installer
├── workflow/
│   ├── code-review/SKILL.md
│   ├── question-details/SKILL.md
│   └── requirements-plan-design-thinking/SKILL.md
└── backend/
    └── write-postgres-sql/SKILL.md
```

## Quick Start

```bash
git clone <this-repo> ~/lyoo-ai-productivity
cd ~/lyoo-ai-productivity
chmod +x install.sh
./install.sh
```

`install.sh` creates symlinks into `~/.copilot/skills`, `~/.cursor/skills`, and `~/.claude/skills`.

## Adding a New Skill

```bash
mkdir -p backend/redis-expert
# create backend/redis-expert/SKILL.md
# add the symlink line to install.sh
```

## Skills

| Skill | Category | Purpose |
|---|---|---|
| code-review | workflow | PR review, merge readiness |
| question-details | workflow | Requirement clarification |
| requirements-plan-design-thinking | workflow | Feature design & trade-offs |
| write-postgres-sql | backend | PostgreSQL query generation |
