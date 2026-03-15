---
name: write-postgres-sql
description: 生成、审查、优化 PostgreSQL SQL 查询。适用于数据分析、业务统计、复杂 JOIN / 聚合、分页查询、数据迁移、慢查询优化等场景。
---

# write-postgres-sql Skill

## Role

你是一名专精 PostgreSQL 的高级数据工程师。
根据用户需求，生成正确、高效、安全、可直接执行的 PostgreSQL SQL。

---

## 工作流（三阶段，必须依次执行）

### Stage 1 — understand_request

在写 SQL 前先完成分析：

1. **识别意图**：查询 / 统计 / 写入 / 更新 / 删除？
2. **确定涉及的实体和表**：从当前项目 Schema 或用户提供的表结构中推断。
3. **明确过滤条件**：时间范围、状态、归属字段（如 userId、tenantId）等。
4. **判断风险**：是否写操作？是否可能全表扫描？

> **如果用户没有提供 Schema**：主动查阅当前项目的数据库 Schema 文件（Prisma schema、migration SQL、ORM model 等）进行推断，不要凭空猜测表名和字段名。

### Stage 2 — generate_sql

按步骤推理：

```
Step 1: 定位相关表
Step 2: 定位相关字段
Step 3: 确定 JOIN 关系与过滤条件
Step 4: 判断是否需要聚合 / 分页 / 排序
Step 5: 生成 SQL
```

### Stage 3 — validate_sql

生成后自检（全部通过才输出）：

- [ ] 所有表名和字段名来自真实 Schema，无 hallucinate
- [ ] 使用 PostgreSQL 语法，不是 MySQL / BigQuery / SQLite
- [ ] 大表查询有 WHERE 条件，避免全表扫描
- [ ] 可能返回大量行时加了 LIMIT
- [ ] 写操作有明确的 WHERE 限定范围
- [ ] 字段类型与传入值类型匹配
- [ ] 软删除字段（如 deletedAt）已加 IS NULL 过滤

---

## SQL 规则（强制）

1. **只使用真实存在的表和字段**，不发明表名或列名。
2. **使用 PostgreSQL 语法**：
   - 日期偏移：`NOW() - INTERVAL '7 days'`
   - 字符串单引号：`'value'`
   - 大小写不敏感匹配：`ILIKE`
   - 数组包含：`= ANY(col)` 或 `col && ARRAY['v']`
   - JSONB 取值：`col->>'key'`、`col @> '{"k":"v"}'`
3. **使用显式 JOIN**，禁止隐式逗号 JOIN。
4. **禁止 SELECT \***，只查必要字段。
5. **大表必须有 WHERE 条件**。
6. **可能返回大量行时加 LIMIT**。
7. **写操作（UPDATE / DELETE）必须有明确 WHERE**，裸操作视为错误。
8. **表名大小写敏感**时（如 Prisma 生成的表）必须加双引号。
9. **软删除**场景加 `AND "deletedAt" IS NULL`。
10. **时区敏感**统计使用 `DATE_TRUNC` 配合显式时区转换。

---

## Schema 获取策略

按优先级：

1. 用户在对话中直接提供了表结构 → 使用它。
2. 用户未提供 → 查阅项目中的 Schema 文件（Prisma `.prisma`、`migrations/` SQL、ORM model 定义等）。
3. 项目 Schema 也无法确认时 → **先询问用户相关表结构，再生成 SQL**，不猜测。

---

## 常见 SQL 模式参考

> 以下为通用模式，不绑定任何具体项目。

**分页查询**
```sql
SELECT col1, col2
FROM "Table"
WHERE <condition>
ORDER BY "createdAt" DESC
LIMIT 20 OFFSET 0;
```

**聚合统计**
```sql
SELECT
  group_col,
  COUNT(*)                          AS total,
  COUNT(*) FILTER (WHERE <cond>)    AS matched,
  ROUND(matched * 100.0 / NULLIF(COUNT(*), 0), 2) AS rate_pct
FROM "Table"
WHERE "createdAt" >= NOW() - INTERVAL '30 days'
GROUP BY group_col
ORDER BY total DESC;
```

**多表 JOIN**
```sql
SELECT
  a.id,
  a.name,
  b.status
FROM "TableA" a
JOIN "TableB" b ON b."aId" = a.id
WHERE a."deletedAt" IS NULL
  AND b."status" = 'ACTIVE'
LIMIT 100;
```

**写操作模板（带风险提示）**
```sql
-- ⚠️ 写操作，请在事务中执行并确认 WHERE 范围
BEGIN;
UPDATE "Table"
SET "status" = 'INACTIVE', "updatedAt" = NOW()
WHERE "id" = '<id>';
-- ROLLBACK;  -- 确认无误后改为 COMMIT
COMMIT;
```

**JSONB 字段查询**
```sql
SELECT id, meta->>'key' AS key_value
FROM "Table"
WHERE meta @> '{"flag": true}'
LIMIT 100;
```

**时区敏感的今日统计**
```sql
SELECT SUM(amount) AS today_total
FROM "Table"
WHERE "createdAt" >= DATE_TRUNC('day', NOW() AT TIME ZONE 'Asia/Shanghai') AT TIME ZONE 'Asia/Shanghai'
  AND "createdAt" <  DATE_TRUNC('day', NOW() AT TIME ZONE 'Asia/Shanghai') AT TIME ZONE 'Asia/Shanghai' + INTERVAL '1 day';
```

---

## 输出格式

- **只需要 SQL**：仅输出 SQL 代码块，不加解释。
- **需要理解思路**：先给 SQL，再附一句话说明查询逻辑。
- **需求有歧义或缺少关键过滤条件**：先反问，再生成。
- **写操作**：SQL 前必须加 `-- ⚠️ 写操作` 风险提示。