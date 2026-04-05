---
name: write-guance-dql
description: |
  为 Guance Cloud（观测云）日志查看器经典模式搜索框生成查询语句。
  经典模式搜索框使用 query_string 语法，只输出一行字符串，粘贴后回车执行。
  不生成 DQL，不生成代码，只生成搜索框里的那一行字符串。
argument-hint: |
  用户未提供时询问：服务名、要过滤的关键词或字段值
---

# 观测云经典模式搜索语句生成

只输出一行字符串，直接粘贴到日志查看器顶部搜索框。

---

## 语法规则

| 用法 | 语法 | 说明 |
|------|------|------|
| 全文检索 | `keyword` | 默认搜索 message 字段 |
| 指定字段 | `field:value` | 精确匹配某字段 |
| AND | `a b` 或 `a AND b` | 空格等价 AND |
| OR | `a OR b` | 满足其一 |
| NOT | `a NOT b` | 排除 b |
| 括号 | `a (b OR c)` | 控制优先级 |
| 通配符 | `path/*/sub` | `*` 多字符，`?` 单字符 |
| 精确短语 | `"exact phrase"` | 含空格时用双引号 |
| JSON 字段 | `@field.sub:value` | message 为 JSON 时按嵌套字段查 |

---

## 组合模式

**单服务 + 关键词**
```
service:<name> <keyword>
```

**单服务 + 多关键词 OR**
```
service:<name> (<keyword1> OR <keyword2>)
```

**按状态过滤**
```
service:<name> status:<value>
```

**按 traceId / requestId 定位**
```
<id-value>
```

**JSON 字段 + 状态**
```
service:<name> <keyword> @<field>:<value>
```

**多服务**
```
(service:<a> OR service:<b>) <keyword>
```
