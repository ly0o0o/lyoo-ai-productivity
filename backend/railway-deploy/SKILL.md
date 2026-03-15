---
name: railway-deploy
description: 在 Railway.app 上部署和管理应用。适用于项目部署、服务管理、日志查看、环境变量配置、数据库管理。Railway 是现代云平台，支持零配置部署。
metadata:
  {"openclaw":{"emoji":"🚂","requires":{"bins":["railway"]},"install":[{"id":"brew","kind":"brew","formula":"railway","bins":["railway"],"label":"安装 Railway CLI (brew)"},{"id":"npm","kind":"npm","package":"@railway/cli","bins":["railway"],"label":"安装 Railway CLI (npm)"}]}}
---

# Railway 部署专家

[Railway.app](https://railway.app) 现代云平台，零配置部署，支持自动 HTTPS、数据库一键开通、环境隔离。

## 认证

```bash
railway login           # 浏览器登录
railway login --token <TOKEN>  # Token 登录（CI/CD 场景）
railway whoami          # 查看当前登录状态
railway logout
```

## 项目管理

```bash
railway init            # 当前目录创建新项目
railway link            # 关联已有项目
railway link --project <PROJECT_ID>
railway unlink
railway list            # 列出所有项目
railway status          # 查看项目状态
railway open            # 在浏览器打开项目面板
```

## 部署

```bash
railway up                              # 部署当前目录
railway up --detach                     # 部署后不跟踪日志（CI 推荐）
railway up --service <SERVICE>          # 指定服务部署
railway up --environment production     # 指定环境部署
railway redeploy                        # 重新部署最新版本
railway redeploy --service <SERVICE>
```

### 从模板部署

```bash
railway deploy --template <TEMPLATE>
railway deploy --template postgres --variable POSTGRES_USER=myuser
```

## 服务管理

```bash
railway service                  # 列出项目内所有服务
railway service create           # 创建新服务
railway service delete <SERVICE>
```

## 环境变量

```bash
railway variables                        # 列出所有变量
railway variables set KEY=value          # 设置单个变量
railway variables set K1=v1 K2=v2        # 批量设置
railway variables get KEY                # 查看单个变量
railway variables delete KEY
```

> 推荐：敏感变量（DB 密码、API Key）只在 Railway 面板设置，不写进代码仓库。

## 日志

```bash
railway logs                             # 实时日志
railway logs --service <SERVICE>         # 指定服务日志
railway logs --no-follow                 # 查看近期日志（不跟踪）
railway logs --timestamps                # 带时间戳
```

## 在 Railway 环境中运行命令

```bash
railway run <command>           # 注入 Railway 环境变量后执行命令
railway run npm start
railway run python manage.py migrate
railway run prisma db push
railway ssh                     # SSH 进入运行中的容器
railway ssh --service <SERVICE>
```

## 域名

```bash
railway domain                  # 列出域名
railway domain add <DOMAIN>     # 绑定自定义域名
railway domain delete <DOMAIN>
```

## 数据库（一键开通）

```bash
railway add --plugin postgresql
railway add --plugin mysql
railway add --plugin redis
railway add --plugin mongodb
```

开通后连接字符串自动注入为环境变量（如 `DATABASE_URL`），无需手动配置。

## 环境管理

```bash
railway environment                      # 列出所有环境
railway environment <ENV_NAME>           # 切换环境
railway environment create <ENV_NAME>
railway environment delete <ENV_NAME>
```

## 持久化存储（Volumes）

```bash
railway volume                           # 列出 volumes
railway volume create --mount /data      # 创建并挂载
railway volume delete <VOLUME_ID>
```

## 常用工作流

### 新项目从零部署

```bash
cd my-app
railway init
railway add --plugin postgresql          # 按需添加数据库
railway variables set NODE_ENV=production
railway up
```

### 本地连接生产数据库

```bash
railway run psql $DATABASE_URL           # 注入生产环境变量后执行
railway ssh                              # 或直接 SSH 进容器
```

### 查看部署状态

```bash
railway status
railway logs
railway open
```

### 回滚

```bash
# 方式一：面板操作（推荐）
railway open   # 在 Deployments 页面点击历史版本 Redeploy

# 方式二：代码回滚后重新部署
git revert HEAD
railway up
```

## CI/CD（GitHub Actions）

```yaml
# .github/workflows/deploy.yml
name: Deploy to Railway
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Railway CLI
        run: npm i -g @railway/cli
      - name: Deploy
        run: railway up --detach
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
```

> `RAILWAY_TOKEN` 在 Railway 面板 → Account Settings → Tokens 生成，存入 GitHub Secrets。

## 最佳实践

- 生产环境单独建 environment，与 staging 隔离
- 数据库连接字符串用 Railway 自动注入的 `$DATABASE_URL`，不要硬编码
- 部署前用 `railway run` 跑 migration，确保 DB schema 同步
- 日志量大时用 `--no-follow` 避免终端卡死
- 团队项目用 `RAILWAY_TOKEN` 做 CI/CD，不要用个人账号登录

## 参考资料

- [Railway 文档](https://docs.railway.com)
- [CLI 参考](https://docs.railway.com/reference/cli-api)
- [模板市场](https://railway.app/templates)
