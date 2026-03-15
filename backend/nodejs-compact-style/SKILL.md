---
name: nodejs-compact-style
description: Node.js/TypeScript 紧凑代码风格规范。当编写、审查或重构 Node.js/TypeScript 后端代码时触发。核心：无冗余注释、早返回、单行条件、可选链、内联对象、箭头函数简写、无 console.log、三元优于 if-else。
metadata:
  author: lyoo
  version: "1.0"
---

# Node.js Compact Style

**核心原则：删除冗余，保留本质。代码即文档。**

---

## 11 条规则（速查）

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
