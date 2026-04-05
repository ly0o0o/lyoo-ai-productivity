# AI Skills 路由说明

本仓库是所有 AI Agent Skills 的唯一来源。
通过 symlink 将 skills 接入各 IDE，一处维护，全局生效。

## 工作流（Workflow）

- `workflow/code-review` — PR 评审、diff 审查、合并判断、需求漂移识别
- `workflow/question-details` — 需求模糊时强制澄清，先确认再实现
- `workflow/requirements-plan-design-thinking` — 功能方案设计、架构权衡、多路径收敛、反驳不合理需求

## 后端（Backend）

- `backend/write-postgres-sql` — PostgreSQL SQL 生成、慢查询优化、Schema 感知查询
- `backend/write-guance-dql` — 观测云日志查看器经典模式搜索语句生成：query_string 语法，支持字段过滤、AND/OR/NOT、通配符、JSON 字段查询
- `backend/write-mongodb-query` — MongoDB 增删改查语句生成，区分 Navicat（shell 语法）和 Compass（GUI 过滤器语法），Schema 感知、索引分析、多方案对比
- `backend/nodejs-compact-style` — Node.js/TypeScript 紧凑代码风格：早返回、无冗余注释、可选链、三元运算符、无 console.log
- `backend/railway-deploy` — Railway.app 部署、服务管理、环境变量、数据库一键开通、CI/CD 集成

## 设计（Design）

- `design/ui-ux-pro-max` — UI/UX 方案设计、组件实现、交互优化、可访问性、设计系统对齐

## 支持的 IDE

| IDE | Skills 目录 |
|---|---|
| GitHub Copilot | `~/.copilot/skills` |
| Cursor | `~/.cursor/skills` |
| Claude Code | `~/.claude/skills` |
| Kiro | `~/.kiro/skills` |
| Codex CLI | `~/.codex/skills` |

## 安装

```bash
chmod +x install.sh
./install.sh
```
