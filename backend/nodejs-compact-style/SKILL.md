---
name: nodejs-compact-style
description: Node.js/TypeScript 优雅紧凑代码风格规范。当编写、审查或重构 Node.js/TypeScript 后端代码时触发。核心：无冗余注释、早返回、单行条件、可选链、内联对象、箭头函数简写、无 console.log、三元优于 if-else、精准命名、单一职责、数组链式、并发优化、类型表达力。
metadata:
  author: lyoo
  version: "1.1"
---

# Node.js Compact Style

**核心原则：删除冗余，保留本质。代码即文档。**

---

## 规则速查（18 条）

### 1. 无多余注释
删除所有 `/** */` 和 `//` 注释。用清晰命名表达意图。

例外：公共 API 的 JSDoc、复杂算法的关键步骤说明。

```ts
// ❌
/** 验证视频信息 @param url 视频 URL */
async function validateVideo(url: string, platform: string) {}

// ✅
async function validateVideo(url: string, platform: AiVideoAnalysisPlatform): Promise<VideoInfo> {}
```

### 2. 早返回（Early Return）
条件满足立即 return，减少嵌套。

```ts
// ❌
async function getQuotaCost(req: FastifyRequest) {
  if (taskId) {
    const task = await findRunningTask(taskId)
    if (task) { return 0 } else { return QuotaCost.AI_VIDEO_ANALYSIS }
  }
}

// ✅
async function getQuotaCost(req: FastifyRequest) {
  if (!req.params.taskId) return QuotaCost.AI_VIDEO_ANALYSIS
  const task = await findRunningTask(req.params.taskId)
  if (task) return 0
  return QuotaCost.AI_VIDEO_ANALYSIS
}
```

### 3. 单行条件
简单条件写一行。

```ts
// ❌
if (!videoId) {
  return QuotaCost.AI_VIDEO_ANALYSIS
}

// ✅
if (!videoId) return QuotaCost.AI_VIDEO_ANALYSIS
if (error) throw error
```

### 4. 可选链
用 `?.` 和 `??` 简化取值。

```ts
// ❌
const fromCache = responseData && responseData.data && responseData.data.fromCache
  ? responseData.data.fromCache : false

// ✅
const fromCache = responseData?.data?.fromCache ?? false
```

**反例**：必传参数不用可选链（见规则 10）。

### 5. 内联对象
简单对象直接 return，不创建中间变量。

```ts
// ❌
const result = { url: url, platform: platform, taskId: task.id }
return result

// ✅
return { url, platform, taskId: task.id }
```

### 6. 避免不必要的解构
同一属性使用少于 3 次时，直接访问原始属性。

```ts
// ❌
const { taskId } = request.params
const task = await findTask(taskId)

// ✅
const task = await findTask(request.params.taskId)
```

例外：同一属性使用 3 次及以上时，解构。

### 7. 箭头函数简写
单表达式省略 `return` 和 `{}`。

```ts
// ❌
const getCost = (data) => { return data?.fromCache ? 0 : QuotaCost.AI_VIDEO_ANALYSIS }
items.map((item) => { return item.id })

// ✅
const getCost = (data) => (data?.fromCache ? 0 : QuotaCost.AI_VIDEO_ANALYSIS)
items.map(item => item.id)
```

### 8. 删除多余空行
逻辑块之间不留多余空行。

```ts
// ❌
async function processTask(taskId: string) {
  const task = await findTask(taskId)

  if (!task) return null

  const result = await analyzeTask(task)

  return result
}

// ✅
async function processTask(taskId: string) {
  const task = await findTask(taskId)
  if (!task) return null
  const result = await analyzeTask(task)
  return result
}
```

例外：超过 50 行的函数可适当加空行分隔逻辑块。

### 9. 无 console.log
生产代码用正式日志系统（`request.log`、Sentry 等）。

```ts
// ❌
console.log('上传文件:', file)

// ✅
request.log.info({ file }, 'File upload started')
```

例外：`src/scripts/` 目录的开发调试脚本可用 console.log。

### 10. 必传参数不用可选链
已确认存在的对象直接调用。

```ts
// ❌
function recordMetrics(metrics: TaskMetrics, duration: number) {
  metrics?.set('duration', duration)
}

// ✅
function recordMetrics(metrics: TaskMetrics, duration: number) {
  metrics.set('duration', duration)
}
```

### 11. 三元优于 if-else
简单条件赋值用三元运算符。

```ts
// ❌
let cost
if (fromCache) { cost = 0 } else { cost = QuotaCost.AI_VIDEO_ANALYSIS }

// ✅
const cost = fromCache ? 0 : QuotaCost.AI_VIDEO_ANALYSIS
```

---

### 12. 精准命名
名字要说清楚"是什么"或"做什么"，不用缩写，不用泛型词。

```ts
// ❌ 泛型、无意义
const data = await getData(id)
const res = process(data)
const flag = check(user)
const temp = items.filter(i => i.active)

// ✅ 自解释
const invoice = await fetchInvoiceById(invoiceId)
const enrichedInvoice = attachLineItems(invoice)
const hasActiveSubscription = checkSubscriptionStatus(user)
const activeItems = items.filter(item => item.active)
```

规则：
- 布尔值用 `is/has/can/should` 前缀
- 异步函数用 `fetch/load/save/create/delete` 等动词
- 不用 `data/info/result/temp/obj/item` 这类无意义词
- 数组用复数：`users` 不是 `userList`

### 13. 函数单一职责
一个函数只做一件事。超过 20 行考虑拆分。

```ts
// ❌ 一个函数做了三件事
async function handleVideoUpload(req: FastifyRequest) {
  // 验证
  if (!req.body.url) throw new Error('Missing url')
  const videoId = extractVideoId(req.body.url)
  if (!videoId) throw new Error('Invalid url')
  // 查缓存
  const cached = await prisma.task.findFirst({ where: { videoId } })
  if (cached) return cached
  // 创建任务
  const task = await prisma.task.create({ data: { videoId, status: 'PENDING' } })
  await queue.add('analyze', { taskId: task.id })
  return task
}

// ✅ 拆成三个职责清晰的函数
function validateVideoUrl(url: string): string {
  if (!url) throw new Error('Missing url')
  const videoId = extractVideoId(url)
  if (!videoId) throw new Error('Invalid url')
  return videoId
}

async function findCachedTask(videoId: string) {
  return prisma.task.findFirst({ where: { videoId } })
}

async function createAnalysisTask(videoId: string) {
  const task = await prisma.task.create({ data: { videoId, status: 'PENDING' } })
  await queue.add('analyze', { taskId: task.id })
  return task
}

async function handleVideoUpload(req: FastifyRequest) {
  const videoId = validateVideoUrl(req.body.url)
  return (await findCachedTask(videoId)) ?? createAnalysisTask(videoId)
}
```

### 14. 数组链式方法
用 `filter/map/find/reduce` 替代命令式循环，表达意图更清晰。

```ts
// ❌ 命令式，噪音多
const activeUserIds: string[] = []
for (const user of users) {
  if (user.active) {
    activeUserIds.push(user.id)
  }
}

// ✅ 声明式，一眼看懂
const activeUserIds = users.filter(u => u.active).map(u => u.id)
```

```ts
// ❌
let total = 0
for (const item of lineItems) {
  total += item.price * item.quantity
}

// ✅
const total = lineItems.reduce((sum, item) => sum + item.price * item.quantity, 0)
```

例外：链式超过 3 步或逻辑复杂时，拆成多行并加变量名说明意图。

### 15. Promise 并发
无依赖的异步操作用 `Promise.all` 并发，不串行 await。

```ts
// ❌ 串行，慢 2 倍
const user = await fetchUser(userId)
const plan = await fetchPlan(planId)

// ✅ 并发
const [user, plan] = await Promise.all([fetchUser(userId), fetchPlan(planId)])
```

```ts
// ❌ 循环里 await，N 次串行
for (const id of taskIds) {
  await processTask(id)
}

// ✅ 并发处理（注意控制并发数量避免打爆下游）
await Promise.all(taskIds.map(id => processTask(id)))
```

### 16. 提取魔法值
数字和字符串字面量提取为具名常量，放在文件顶部或 constants 文件。

```ts
// ❌ 魔法数字/字符串
if (retryCount > 3) throw new Error('Too many retries')
await sleep(5000)
if (user.role === 'admin') return true

// ✅
const MAX_RETRY_COUNT = 3
const RETRY_DELAY_MS = 5000
const ROLE_ADMIN = 'admin'

if (retryCount > MAX_RETRY_COUNT) throw new Error('Too many retries')
await sleep(RETRY_DELAY_MS)
if (user.role === ROLE_ADMIN) return true
```

### 17. 错误处理：避免吞错
catch 块必须处理错误，不能静默忽略。错误要带上下文再抛出。

```ts
// ❌ 吞掉错误，调试噩梦
try {
  await uploadFile(path)
} catch (e) {}

// ❌ 丢失上下文
try {
  await uploadFile(path)
} catch (e) {
  throw new Error('Upload failed')
}

// ✅ 保留原始错误上下文
try {
  await uploadFile(path)
} catch (cause) {
  throw new Error(`Failed to upload file: ${path}`, { cause })
}
```

### 18. 类型表达力
用类型系统表达业务约束，不用 `any`，不用宽泛类型。

```ts
// ❌ 类型没有表达业务含义
function createTask(type: string, status: string, data: any) {}
const userId: string = '...'

// ✅ 类型即文档
type TaskType = 'VIDEO_ANALYSIS' | 'IMAGE_RESIZE' | 'AUDIO_TRANSCRIBE'
type TaskStatus = 'PENDING' | 'PROCESSING' | 'COMPLETED' | 'FAILED'
type UserId = string & { readonly _brand: 'UserId' }  // Branded type，防止 id 混用

function createTask(type: TaskType, status: TaskStatus, data: TaskPayload) {}
```

```ts
// ❌ 返回类型模糊
async function findUser(id: string) {
  return prisma.user.findFirst({ where: { id } })
}

// ✅ 明确返回类型，调用方一眼知道可能为 null
async function findUser(id: string): Promise<User | null> {
  return prisma.user.findFirst({ where: { id } })
}
```

---

## 完整对比

```ts
// ❌ 冗长风格（40 行）
/**
 * 获取 AI 视频分析任务的配额成本
 */
async function getAiVideoAnalysisQuotaCost(request: FastifyRequest) {
  // 从请求参数中提取 taskId
  const { taskId } = request.params
  if (taskId) {
    const runningTask = await prisma.task.findFirst({
      where: { id: taskId, status: TaskStatus.PROCESSING }
    })
    if (runningTask) { return 0 }
  }
  const { url } = request.body
  const videoId = parseUrlUtils.extractVideoId(url)
  if (!videoId) { return QuotaCost.AI_VIDEO_ANALYSIS }
  const cachedTask = await prisma.task.findFirst({
    where: { params: { path: ['videoId'], equals: videoId }, status: TaskStatus.COMPLETED }
  })
  if (cachedTask) { return 0 } else { return QuotaCost.AI_VIDEO_ANALYSIS }
}

// ✅ 紧凑风格（13 行）
async function getAiVideoAnalysisQuotaCost(request: FastifyRequest) {
  if (request.params.taskId) {
    const runningTask = await prisma.task.findFirst({
      where: { id: request.params.taskId, status: TaskStatus.PROCESSING }
    })
    if (runningTask) return 0
  }
  const videoId = parseUrlUtils.extractVideoId(request.body.url)
  if (!videoId) return QuotaCost.AI_VIDEO_ANALYSIS
  const cachedTask = await prisma.task.findFirst({
    where: { params: { path: ['videoId'], equals: videoId }, status: TaskStatus.COMPLETED }
  })
  return cachedTask ? 0 : QuotaCost.AI_VIDEO_ANALYSIS
}
```

---

## 放宽条件

| 场景 | 可放宽的规则 |
|---|---|
| 复杂业务逻辑 | 可加空行分隔逻辑块 |
| 函数超过 50 行 | 可适当加空行 |
| 公共 API | 可保留 JSDoc |
| 复杂算法 | 可加关键步骤注释 |
| `src/scripts/` 调试脚本 | 可用 console.log |

---

## 工具配置

```js
// .eslintrc.cjs
module.exports = {
  rules: {
    'no-console': 'error',
    'no-multiple-empty-lines': ['error', { max: 1 }],
    'prefer-arrow-callback': 'error',
    'arrow-body-style': ['error', 'as-needed'],
  }
}
```

```json
// prettier.config.json
{
  "printWidth": 100,
  "semi": false,
  "singleQuote": true,
  "trailingComma": "all"
}
```
