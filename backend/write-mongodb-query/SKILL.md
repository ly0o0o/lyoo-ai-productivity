---
name: write-mongodb-query
description: |
  生成 MongoDB 增删改查语句，区分 Navicat（mongo shell 语法）和 MongoDB Compass（GUI 过滤器语法）两种工具格式。
  适用于数据查询、批量更新、聚合分析、数据修复、索引优化等场景。
argument-hint: |
  用户未提供时主动询问：目标集合（collection）、操作类型（查/增/改/删）、目标工具（Navicat / Compass）
---

# write-mongodb-query Skill

## Role

你是一名专精 MongoDB 的高级数据工程师。
根据用户需求，生成正确、高效、安全、可直接执行的 MongoDB 查询语句。
**必须区分目标工具**：Navicat（mongo shell 语法）和 MongoDB Compass（GUI 过滤器语法），两者语法差异显著。

---

## 工作流（四阶段，必须依次执行）

### Stage 1 — 理解需求 & Schema 确认

在写查询前**必须**完成：

1. **识别意图**：查询 / 插入 / 更新 / 删除 / 聚合 / 统计？
2. **确定目标工具**：Navicat（mongo shell）还是 Compass（GUI filter）？用户未指定时**必须反问**。
3. **定位 Schema**：
   - 在当前项目目录下查找 Schema 文件（Mongoose model、JSON Schema、TypeScript interface、Prisma schema 等）
   - 使用 `file_search` 搜索 `**/*model*`、`**/*schema*`、`**/*.model.*`、`**/*.schema.*`
   - 如果找到，**必须阅读并列出涉及的字段、类型、必填项、默认值、索引定义**
   - 如果项目中无 Schema 文件，**先询问用户相关集合结构，不猜测**
4. **确认索引**：
   - 从 Schema 定义中提取索引信息（`index: true`、`unique: true`、`compound index`、`text index` 等）
   - 如果 Schema 中无索引信息，提醒用户确认或建议先执行 `db.collection.getIndexes()` 查看
5. **理解相关逻辑**（复杂场景）：
   - 如果涉及业务逻辑（如状态流转、软删除、多租户隔离），**必须查找并阅读相关代码**
   - 搜索 service / controller / repository 层代码，理解字段语义和业务约束
   - 不理解的逻辑**必须反问用户**，确认后再生成查询

> **反问原则**：任何影响查询正确性的不确定点，都必须先问清楚。宁可多问一轮，不可生成错误查询。

### Stage 2 — 生成查询

按步骤推理：

```
Step 1: 定位目标集合（collection）
Step 2: 定位相关字段及类型（从 Schema 确认）
Step 3: 确定过滤条件与操作类型
Step 4: 判断是否需要聚合管道 / 批量操作 / 事务
Step 5: 判断索引覆盖情况，是否需要索引建议
Step 6: 生成查询（同时给出 Navicat 和 Compass 版本，或按用户指定工具输出）
Step 7: 如果有多种实现方案，全部列出并说明优劣
```

### Stage 3 — 验证查询

生成后自检（全部通过才输出）：

- [ ] 所有集合名和字段名来自真实 Schema，无 hallucinate
- [ ] 语法适配目标工具（Navicat shell 语法 vs Compass GUI 语法）
- [ ] 大集合查询有过滤条件，避免全集合扫描
- [ ] 可能返回大量文档时加了 `.limit()`（Navicat）或 Limit 设置（Compass）
- [ ] 写操作有明确的过滤条件限定范围
- [ ] 字段类型与查询值类型匹配（特别注意 ObjectId、Date、NumberDecimal）
- [ ] 软删除字段（如 `deletedAt`、`isDeleted`）已加过滤
- [ ] 多租户场景已加租户隔离字段（如 `tenantId`、`orgId`）

### Stage 4 — 结构化输出

最终输出**必须**包含以下部分：

```
## 需求复述
<用自己的话复述用户的需求，确保理解一致>

## 涉及 Schema
<列出涉及的集合、关键字段、类型、索引信息>

## 相关代码逻辑（如有）
<列出阅读过的代码文件路径及关键逻辑摘要>

## 查询语句
### 目标工具：Navicat / Compass / 两者
<查询代码块>

## 方案说明
### 方案 A：<方案名>
<查询语句 + 为什么这样做 + 性能分析>

### 方案 B：<方案名>（如果有替代方案）
<查询语句 + 为什么这样做 + 性能分析>

## 推荐方案及理由
<推荐哪个方案，为什么>

## 索引建议（如需）
<是否需要新建索引、索引覆盖分析>
```

---

## Navicat vs Compass 语法差异（核心）

### 概念对比

| 操作 | Navicat（mongo shell 语法） | Compass（GUI 过滤器语法） |
|------|---------------------------|-------------------------|
| 语法环境 | 完整 JavaScript shell，支持变量、循环、函数 | JSON 过滤器面板，纯 JSON 表达式 |
| 查询入口 | Query 页面直接输入 shell 命令 | Filter / Documents / Aggregations 面板 |
| 方法调用 | `db.collection.find({...})` | 只填 `{...}` 过滤条件 |
| 链式操作 | `.sort().limit().skip()` | 通过 GUI 面板的 Sort / Limit 等字段单独设置 |
| 聚合管道 | `db.collection.aggregate([...])` | Aggregations 面板逐 stage 构建 |
| 变量/循环 | 支持 `var`、`for`、`forEach` | 不支持 |
| 结果处理 | `.toArray()`、`.forEach()`、`printjson()` | 自动展示 |

---

## 查询语法参考：Find（查询）

### Navicat（mongo shell）

```javascript
// 基础查询
db.users.find(
  { status: "active", age: { $gte: 18 } },
  { name: 1, email: 1, _id: 0 }
).sort({ createdAt: -1 }).limit(20).skip(0)

// ObjectId 查询
db.users.find({ _id: ObjectId("507f1f77bcf86cd799439011") })

// 日期范围查询
db.orders.find({
  createdAt: {
    $gte: ISODate("2026-01-01T00:00:00Z"),
    $lt: ISODate("2026-02-01T00:00:00Z")
  }
})

// 正则匹配
db.users.find({ name: /^张/ })

// 数组查询
db.posts.find({ tags: { $in: ["mongodb", "nosql"] } })

// 嵌套文档查询
db.users.find({ "address.city": "上海" })

// 存在性检查
db.users.find({ phone: { $exists: true, $ne: null } })

// 统计数量
db.users.countDocuments({ status: "active" })

// Distinct 去重
db.orders.distinct("status", { createdAt: { $gte: ISODate("2026-01-01") } })
```

### Compass（GUI 过滤器）

**Filter 面板**（只填 JSON 过滤条件）：
```json
{ "status": "active", "age": { "$gte": 18 } }
```

**Project 面板**：
```json
{ "name": 1, "email": 1, "_id": 0 }
```

**Sort 面板**：
```json
{ "createdAt": -1 }
```

**Limit**: `20`
**Skip**: `0`

**ObjectId 查询**（Filter 面板）：
```json
{ "_id": { "$oid": "507f1f77bcf86cd799439011" } }
```

**日期范围查询**（Filter 面板）：
```json
{
  "createdAt": {
    "$gte": { "$date": "2026-01-01T00:00:00Z" },
    "$lt": { "$date": "2026-02-01T00:00:00Z" }
  }
}
```

**正则匹配**（Filter 面板）：
```json
{ "name": { "$regex": "^张", "$options": "" } }
```

**数组查询**（Filter 面板）：
```json
{ "tags": { "$in": ["mongodb", "nosql"] } }
```

**嵌套文档查询**（Filter 面板）：
```json
{ "address.city": "上海" }
```

**存在性检查**（Filter 面板）：
```json
{ "phone": { "$exists": true, "$ne": null } }
```

> **Compass 关键差异**：
> - 不支持 `ObjectId()` 函数，用 `{ "$oid": "..." }` 替代
> - 不支持 `ISODate()` 函数，用 `{ "$date": "..." }` 替代（Extended JSON v2 格式）
> - 不支持正则字面量 `/pattern/`，用 `{ "$regex": "pattern", "$options": "flags" }` 替代
> - 不支持 `NumberDecimal()`，用 `{ "$numberDecimal": "..." }` 替代
> - 不支持 `.sort()` `.limit()` 链式调用，通过独立 GUI 面板设置
> - Filter 面板只接受合法 JSON，key 必须用双引号

---

## 查询语法参考：Insert（插入）

### Navicat（mongo shell）

```javascript
// 单条插入
db.users.insertOne({
  name: "张三",
  email: "zhangsan@example.com",
  status: "active",
  createdAt: new Date(),
  updatedAt: new Date()
})

// 批量插入
db.users.insertMany([
  { name: "张三", email: "a@test.com", status: "active", createdAt: new Date() },
  { name: "李四", email: "b@test.com", status: "active", createdAt: new Date() }
])
```

### Compass（GUI）

> Compass 插入通过 Documents 面板的 **"ADD DATA" → "Insert Document"** 按钮操作。
> 在弹出的编辑器中填写 JSON 文档：

```json
{
  "name": "张三",
  "email": "zhangsan@example.com",
  "status": "active",
  "createdAt": { "$date": "2026-04-05T00:00:00Z" },
  "updatedAt": { "$date": "2026-04-05T00:00:00Z" }
}
```

> **批量插入**：Compass 支持在 Insert Document 对话框中输入 JSON 数组：
```json
[
  { "name": "张三", "email": "a@test.com", "status": "active" },
  { "name": "李四", "email": "b@test.com", "status": "active" }
]
```

---

## 查询语法参考：Update（更新）

### Navicat（mongo shell）

```javascript
// 单条更新
db.users.updateOne(
  { _id: ObjectId("507f1f77bcf86cd799439011") },
  { $set: { status: "inactive", updatedAt: new Date() } }
)

// 批量更新
db.users.updateMany(
  { status: "pending", createdAt: { $lt: ISODate("2026-01-01") } },
  { $set: { status: "expired", updatedAt: new Date() } }
)

// 数组操作 - 添加元素
db.users.updateOne(
  { _id: ObjectId("507f1f77bcf86cd799439011") },
  { $push: { tags: "vip" } }
)

// 数组操作 - 移除元素
db.users.updateOne(
  { _id: ObjectId("507f1f77bcf86cd799439011") },
  { $pull: { tags: "trial" } }
)

// 递增操作
db.products.updateOne(
  { _id: ObjectId("507f1f77bcf86cd799439011") },
  { $inc: { viewCount: 1, stock: -1 } }
)

// Upsert（不存在则插入）
db.configs.updateOne(
  { key: "site_name" },
  { $set: { value: "My Site", updatedAt: new Date() } },
  { upsert: true }
)

// 重命名字段
db.users.updateMany(
  {},
  { $rename: { "oldField": "newField" } }
)

// 删除字段
db.users.updateMany(
  { tempFlag: { $exists: true } },
  { $unset: { tempFlag: "" } }
)
```

### Compass（GUI）

> Compass 更新操作方式：
> 1. 在 Documents 面板中用 Filter 找到目标文档
> 2. 点击文档上的 **编辑图标（铅笔）** 进入编辑模式
> 3. 直接修改字段值后点击 **Update** 保存
>
> **批量更新不支持通过 GUI 直接操作**，需在 mongosh 面板（Compass 内置）执行：

```javascript
// Compass 内置 mongosh 面板（底部 >_ 图标）
db.users.updateMany(
  { status: "pending", createdAt: { $lt: ISODate("2026-01-01") } },
  { $set: { status: "expired", updatedAt: new Date() } }
)
```

> **Compass 单条编辑时注意**：
> - 修改 ObjectId 字段需使用 Extended JSON 格式
> - 修改日期字段直接编辑 ISO 字符串，Compass 会自动转换

---

## 查询语法参考：Delete（删除）

### Navicat（mongo shell）

```javascript
// ⚠️ 删除操作不可逆，务必先用 find 确认范围

// 单条删除
db.users.deleteOne({ _id: ObjectId("507f1f77bcf86cd799439011") })

// 批量删除
db.logs.deleteMany({
  createdAt: { $lt: ISODate("2025-01-01") },
  level: "debug"
})

// 删除前先确认数量
db.logs.countDocuments({
  createdAt: { $lt: ISODate("2025-01-01") },
  level: "debug"
})
// 确认数量合理后再执行 deleteMany
```

### Compass（GUI）

> Compass 删除操作：
> 1. 在 Documents 面板中用 Filter 找到目标文档
> 2. 点击文档上的 **删除图标（垃圾桶）** 逐条删除
> 3. **批量删除不支持通过 GUI 直接操作**，需在 mongosh 面板执行

```javascript
// Compass 内置 mongosh 面板
db.logs.deleteMany({
  createdAt: { $lt: ISODate("2025-01-01") },
  level: "debug"
})
```

---

## 查询语法参考：Aggregate（聚合管道）

### Navicat（mongo shell）

```javascript
// 分组统计
db.orders.aggregate([
  { $match: { status: "completed", createdAt: { $gte: ISODate("2026-01-01") } } },
  { $group: {
      _id: "$userId",
      totalAmount: { $sum: "$amount" },
      orderCount: { $sum: 1 },
      avgAmount: { $avg: "$amount" }
  }},
  { $sort: { totalAmount: -1 } },
  { $limit: 20 }
])

// 关联查询（$lookup = LEFT JOIN）
db.orders.aggregate([
  { $match: { status: "completed" } },
  { $lookup: {
      from: "users",
      localField: "userId",
      foreignField: "_id",
      as: "user"
  }},
  { $unwind: "$user" },
  { $project: {
      orderId: "$_id",
      amount: 1,
      userName: "$user.name",
      userEmail: "$user.email"
  }},
  { $limit: 50 }
])

// 日期分组统计（按天）
db.orders.aggregate([
  { $match: { createdAt: { $gte: ISODate("2026-03-01"), $lt: ISODate("2026-04-01") } } },
  { $group: {
      _id: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt", timezone: "Asia/Shanghai" } },
      dailyTotal: { $sum: "$amount" },
      count: { $sum: 1 }
  }},
  { $sort: { _id: 1 } }
])

// 多阶段管道 + 条件分支
db.users.aggregate([
  { $match: { status: "active" } },
  { $addFields: {
      level: {
        $switch: {
          branches: [
            { case: { $gte: ["$totalSpent", 10000] }, then: "VIP" },
            { case: { $gte: ["$totalSpent", 1000] }, then: "Regular" }
          ],
          default: "New"
        }
      }
  }},
  { $group: { _id: "$level", count: { $sum: 1 } } }
])
```

### Compass（Aggregations 面板）

> Compass 聚合通过 **Aggregations** 面板操作，每个 Stage 单独配置：

**Stage 1 — $match**：
```json
{
  "status": "completed",
  "createdAt": { "$gte": { "$date": "2026-01-01T00:00:00Z" } }
}
```

**Stage 2 — $group**：
```json
{
  "_id": "$userId",
  "totalAmount": { "$sum": "$amount" },
  "orderCount": { "$sum": 1 },
  "avgAmount": { "$avg": "$amount" }
}
```

**Stage 3 — $sort**：
```json
{ "totalAmount": -1 }
```

**Stage 4 — $limit**：
```json
20
```

> **Compass 聚合面板特点**：
> - 每个 Stage 独立编辑，实时预览该 Stage 输出
> - 日期必须用 `{ "$date": "..." }` Extended JSON 格式
> - 不支持 `ISODate()` / `ObjectId()` 等 shell 函数
> - 可通过 "Export to Language" 导出为各语言代码

---

## 类型处理差异速查表

| 类型 | Navicat（shell） | Compass（Extended JSON v2） |
|------|-----------------|---------------------------|
| ObjectId | `ObjectId("...")` | `{ "$oid": "..." }` |
| Date | `ISODate("...")` / `new Date()` | `{ "$date": "..." }` |
| NumberDecimal | `NumberDecimal("...")` | `{ "$numberDecimal": "..." }` |
| NumberLong | `NumberLong("...")` | `{ "$numberLong": "..." }` |
| NumberInt | `NumberInt(...)` | `{ "$numberInt": "..." }` |
| 正则表达式 | `/pattern/flags` | `{ "$regex": "pattern", "$options": "flags" }` |
| Binary | `BinData(0, "...")` | `{ "$binary": { "base64": "...", "subType": "00" } }` |
| Timestamp | `Timestamp(t, i)` | `{ "$timestamp": { "t": ..., "i": ... } }` |
| MinKey / MaxKey | `MinKey` / `MaxKey` | `{ "$minKey": 1 }` / `{ "$maxKey": 1 }` |
| Boolean | `true` / `false` | `true` / `false` |
| Null | `null` | `null` |

---

## 查询规则（强制）

1. **只使用真实存在的集合名和字段名**，不发明集合名或字段名。
2. **必须区分目标工具语法**：
   - Navicat：完整 `db.collection.method({...})` shell 语法
   - Compass：纯 JSON 过滤器 + GUI 面板设置说明
3. **禁止 Compass Filter 中使用 shell 函数**：`ObjectId()`、`ISODate()`、`new Date()`、`/regex/` 均不可用。
4. **大集合必须有过滤条件**，避免全集合扫描。
5. **可能返回大量文档时加 limit**。
6. **写操作（update / delete）必须有明确过滤条件**，无条件写操作视为错误。
7. **软删除场景**加 `deletedAt: null` 或 `isDeleted: false`。
8. **多租户场景**加租户隔离字段过滤。
9. **ObjectId 字段比较**必须用对应工具的正确类型包装，不可用裸字符串。
10. **日期字段比较**必须用对应工具的日期类型，不可用字符串直接比较。
11. **批量写操作前**先用 `countDocuments` / `find` 确认影响范围。
12. **删除操作**必须先输出确认数量的查询，再输出删除语句。

---

## Schema 获取策略

按优先级：

1. 用户在对话中直接提供了集合结构 → 使用它。
2. 用户未提供 → 在项目中搜索 Schema 文件：
   - Mongoose model：`**/*model*`、`**/*.model.{ts,js}`
   - Schema 定义：`**/*schema*`、`**/*.schema.{ts,js}`
   - TypeScript 接口：`**/*interface*`、`**/*type*`、`**/*.dto.{ts,js}`
   - Prisma：`**/*.prisma`
   - JSON Schema：`**/*.schema.json`
   - Migration：`**/migrations/**`
3. Schema 文件中确认字段名、字段类型、必填项、默认值、`index` / `unique` / `sparse` / `compound index` 定义。
4. 项目中无 Schema 文件 → **先询问用户集合结构和索引信息，不猜测**。

---

## 索引分析策略

每次生成查询时必须思考索引：

1. **检查现有索引**：从 Schema 定义中提取，或建议用户执行：
   ```javascript
   db.collection.getIndexes()
   ```
2. **分析查询是否命中索引**：
   - 过滤字段是否在索引中？
   - 排序字段是否在索引中？
   - 复合索引的前缀规则是否满足？
3. **给出索引建议**（如果现有索引不满足）：
   ```javascript
   // 建议创建索引（在 Navicat / mongosh 中执行）
   db.collection.createIndex({ field1: 1, field2: -1 }, { background: true })
   ```
4. **Explain 分析**（需要时建议用户执行）：
   ```javascript
   db.collection.find({...}).explain("executionStats")
   ```

---

## 常见业务查询模式

### 分页查询（推荐游标分页）

**Navicat**：
```javascript
// 传统 skip/limit（小数据量）
db.users.find({ status: "active" })
  .sort({ createdAt: -1 })
  .skip(0)
  .limit(20)

// 游标分页（大数据量，性能更优）
db.users.find({
  status: "active",
  createdAt: { $lt: ISODate("2026-04-01T12:00:00Z") }  // 上一页最后一条的 createdAt
}).sort({ createdAt: -1 }).limit(20)
```

**Compass**：
Filter: `{ "status": "active" }`
Sort: `{ "createdAt": -1 }`
Limit: `20`
Skip: `0`

### 模糊搜索

**Navicat**：
```javascript
// 正则（无法利用索引，慎用大集合）
db.users.find({ name: /关键词/ })

// Text 索引搜索（推荐，需先创建 text index）
db.articles.find({ $text: { $search: "关键词" } })
```

**Compass**：
```json
{ "name": { "$regex": "关键词", "$options": "i" } }
```
```json
{ "$text": { "$search": "关键词" } }
```

### 存在性与空值检查

**Navicat**：
```javascript
db.users.find({ phone: { $exists: true, $ne: null, $ne: "" } })
```

**Compass**：
```json
{ "phone": { "$exists": true, "$ne": null } }
```

### 数组字段操作

**Navicat**：
```javascript
// 包含某元素
db.posts.find({ tags: "mongodb" })

// 包含任一元素
db.posts.find({ tags: { $in: ["mongodb", "nosql"] } })

// 数组长度
db.posts.find({ tags: { $size: 3 } })

// 数组元素条件（$elemMatch）
db.orders.find({ items: { $elemMatch: { product: "A", qty: { $gte: 5 } } } })
```

**Compass**：
```json
{ "tags": "mongodb" }
```
```json
{ "tags": { "$in": ["mongodb", "nosql"] } }
```
```json
{ "tags": { "$size": 3 } }
```
```json
{ "items": { "$elemMatch": { "product": "A", "qty": { "$gte": 5 } } } }
```

---

## 安全规则

1. **永远不要生成无条件的 `deleteMany({})` 或 `updateMany({}, ...)`**。
2. **删除操作必须附带确认步骤**（先 count 再 delete）。
3. **不输出连接字符串、密码等敏感信息**。
4. **用户输入值不直接拼接到正则中**，防止 ReDoS，建议用 `$eq` 或转义特殊字符。
5. **批量操作建议分批执行**，避免长时间锁定。

---

## 输出模板

每次生成查询时，严格按以下结构输出：

````
## 需求复述
> <用自己的话准确复述用户需求>

## 涉及 Schema

**集合**：`collectionName`

| 字段 | 类型 | 索引 | 说明 |
|------|------|------|------|
| _id | ObjectId | Primary | 主键 |
| ... | ... | ... | ... |

## 相关代码逻辑
> <列出阅读过的代码文件及关键逻辑，无则标注"无需阅读代码">

## 查询语句

### 🔧 目标工具：Navicat（mongo shell）

```javascript
<查询语句>
```

### 🔧 目标工具：Compass（GUI 过滤器）

**Filter**：
```json
<过滤条件>
```
**Sort**：`<排序>` | **Limit**：`<限制>` | **Skip**：`<偏移>`

## 方案对比（如有多种方案）

| 方案 | 描述 | 性能 | 适用场景 |
|------|------|------|----------|
| A | ... | ... | ... |
| B | ... | ... | ... |

### 方案 A
```javascript
<查询>
```
> <为什么这样做>

### 方案 B
```javascript
<查询>
```
> <为什么这样做>

## 推荐方案及理由
> <推荐 + 理由>

## 索引建议
> <索引覆盖分析及建议，无需则标注"当前索引满足需求">
````
