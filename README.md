# lyoo-ai-productivity

> 所有 AI Agent Skills 的唯一来源。一个仓库，接入所有 IDE。

## 核心理念

把所有 skills 放在一个 Git 仓库里统一管理，各 IDE 通过 symlink 接入。
这样做的好处：

- 一处修改，所有 IDE 同步生效
- Git 管理版本，随时回滚
- 新电脑一条命令完成全部安装
- 团队可以共享同一套 skills

支持的 IDE / Agent：

- GitHub Copilot (`~/.copilot/skills`)
- Cursor (`~/.cursor/skills`)
- Claude Code (`~/.claude/skills`)
- Kiro (`~/.kiro/skills`)
- Codex CLI (`~/.codex/skills`)

---

## 目录结构

```
lyoo-ai-productivity/
│
├── AGENTS.md                                    # AI agent 路由说明（agent 会读这个）
├── README.md                                    # 本文件
├── install.sh                                   # 一键 symlink 安装脚本（支持 5 个 IDE）
│
├── workflow/                                    # 工作流类 skills
│   ├── code-review/
│   │   └── SKILL.md                            # PR 评审、diff 审查、合并判断
│   ├── question-details/
│   │   └── SKILL.md                            # 需求澄清、反问、确认后再实现
│   └── requirements-plan-design-thinking/
│       └── SKILL.md                            # 方案设计、架构权衡、共创
│
├── backend/                                     # 后端技术类 skills
│   └── write-postgres-sql/
│       └── SKILL.md                            # PostgreSQL 查询生成与优化
│   └── nodejs-compact-style/
│       └── SKILL.md                            # Node.js/TypeScript 紧凑代码风格
│   └── railway-deploy/
│       └── SKILL.md                            # Railway.app 部署与服务管理
│
└── design/                                      # 设计类 skills
    └── ui-ux-pro-max/
        └── SKILL.md                            # UI/UX 方案、组件实现、可访问性
```

---

## 快速开始

### 1. 克隆仓库

```bash
git clone <this-repo-url> ~/lyoo-ai-productivity
cd ~/lyoo-ai-productivity
```

### 2. 运行安装脚本

```bash
chmod +x install.sh
./install.sh
```

脚本会自动把所有 skills 以 symlink 方式链接到：

- `~/.copilot/skills/`
- `~/.cursor/skills/`
- `~/.claude/skills/`

### 3. 验证安装

```bash
ls -la ~/.copilot/skills/
ls -la ~/.cursor/skills/
ls -la ~/.claude/skills/
```

看到 `->` 箭头指向本仓库路径即为成功。

---

## Skills 清单

| Skill | 分类 | 触发场景 |
|---|---|---|
| `code-review` | workflow | PR 评审、diff 审查、合并前检查、需求漂移识别 |
| `question-details` | workflow | 需求模糊时强制澄清，先确认再实现 |
| `requirements-plan-design-thinking` | workflow | 功能方案设计、架构权衡、多路径收敛、反驳不合理需求 |
| `write-postgres-sql` | backend | PostgreSQL SQL 生成、慢查询优化、Schema 感知查询 |
| `nodejs-compact-style` | backend | Node.js/TypeScript 紧凑代码风格：早返回、无注释、可选链、三元运算符 |
| `railway-deploy` | backend | Railway.app 部署、服务管理、环境变量、数据库一键开通、CI/CD 集成 |
| `ui-ux-pro-max` | design | UI/UX 方案设计、组件实现、交互优化、可访问性、设计系统对齐 |

---

## 新增一个 Skill

### 第一步：创建 skill 目录和文件

```bash
mkdir -p backend/redis-expert
```

`backend/redis-expert/SKILL.md` 模板：

```markdown
---
name: redis-expert
description: Redis 缓存设计、Key 策略、过期策略与性能优化。
---

# Redis Expert

## 职责
- 设计合理的 Key 命名规范
- 选择合适的数据结构（String / Hash / ZSet / List）
- 制定过期策略与缓存穿透/击穿/雪崩防护方案

## 最佳实践
- Key 加业务前缀，避免冲突
- 大 Key 拆分，避免阻塞
- 写操作先更新 DB，再删缓存（Cache-Aside）
```

### 第二步：在 install.sh 中添加 symlink

打开 `install.sh`，在 `SKILLS` 数组中加一行：

```bash
"$SKILLS_ROOT/backend/redis-expert"
```

### 第三步：更新 AGENTS.md

在对应分类下补充新 skill 的说明，让 AI agent 知道它的存在。

### 第四步：提交

```bash
git add -A
git commit -m "feat: add redis-expert skill"
git push
```

---

## 换新电脑

```bash
git clone <this-repo-url> ~/lyoo-ai-productivity
cd ~/lyoo-ai-productivity
chmod +x install.sh
./install.sh
```

一条命令，全部 IDE 自动安装完毕。

---

## 目录规范

| 分类目录 | 适合放什么 |
|---|---|
| `workflow/` | 通用工作流：代码评审、需求澄清、方案设计、PR 生成 |
| `backend/` | 后端技术：数据库、缓存、消息队列、性能优化 |
| `design/` | UI/UX 设计：组件设计、交互优化、设计系统、可访问性 |
| `architecture/` | 系统设计：分布式、微服务、数据库设计 |
| `ai/` | AI 工程：Prompt 设计、RAG、Agent 架构 |

## 支持的 IDE

| IDE | Skills 目录 |
|---|---|
| GitHub Copilot | `~/.copilot/skills` |
| Cursor | `~/.cursor/skills` |
| Claude Code | `~/.claude/skills` |
| Kiro | `~/.kiro/skills` |
| Codex CLI | `~/.codex/skills` |
