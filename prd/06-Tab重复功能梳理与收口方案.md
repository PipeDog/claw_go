# 06｜Tab 重复功能梳理与收口方案

## 一、目的

本文聚焦当前 `Claw Go` 不同 Tab 下的重复功能、重复内容与职责交叉问题，并给出收口建议。

核心原则只有一条：

> **每一个一级 Tab 只能回答一个一级问题。**

如果一个页面同时回答多个一级问题，用户就会产生“我应该在这里做，还是去另一个页面做”的犹豫，最终形成重复页面与重复入口。

---

## 二、当前一级 Tab 清单

当前 Root 侧边栏实际包含：

1. Chat
2. Overview
3. Sessions
4. Logs
5. Agents
6. Setup
7. Profiles
8. Console
9. Config
10. Docs
11. Markdown Test

从第一性原理看，这 11 个入口并不都属于“一级导航”。

其中至少有 4 类混在了一起：

1. **用户主任务入口**：Chat / Sessions / Agents
2. **状态与诊断入口**：Overview / Logs / Console
3. **环境管理入口**：Setup / Profiles
4. **设置与文档入口**：Config / Docs / Markdown Test

这就是当前重复感与割裂感的根源。

---

## 三、逐项重复功能梳理

## 3.1 Gateway 控制重复

### 当前分布
1. Header 顶栏
   - 启动 Gateway
   - 重启 Gateway
   - 连接 / 断开 Gateway

2. Chat 页
   - Gateway Control
   - 连接状态
   - Gateway 相关入口

3. Console 页
   - Gateway 连接工作区
   - URL / Token / Password
   - 启停 / 重启 / 连接 / 断开

4. Overview 页
   - Gateway readiness / status 摘要

5. Settings 页
   - 当前 Gateway 状态摘要

### 问题本质
同一个核心对象 `Gateway`，被拆散在 5 个入口中反复表达。

用户无法快速回答：
- “我应该在哪里真正连接？”
- “我在哪里看连接状态？”
- “我在哪里排障？”

### 收口建议
- **唯一主入口**：Console / 后续可更名为 `Connect`
- **只保留摘要**：Header、Overview、Settings
- **Chat 中移除完整 Gateway 工作区**，只保留极轻量状态提示或失败提示

### 结论
`Gateway 控制` 不应再横向铺在多个一级 Tab 中，它应该收敛成一个独立工作区，其他页面只读引用其状态。

---

## 3.2 Agent 相关内容重复

### 当前分布
1. Chat 页
   - Agent / Model 选择
   - 当前 Agent 聊天记录

2. Agents 页
   - Agent 列表
   - 当前 Agent 概览
   - 最近会话预览

3. Sessions 页
   - 当前 Agent 视角 / 全部任务视角切换

### 问题本质
同一层语义的内容被拆成了多个入口：
- 选 Agent
- 看 Agent 资产
- 看 Agent 会话

这些本来属于一个连续工作流，但当前被拆散在 Chat / Agents / Sessions 三页。

### 收口建议
- **Agents**：只负责 Agent 资产与工作区导航
- **Chat**：只负责当前 Agent 的对话与任务发起
- **Sessions**：只负责当前 Agent / 全部任务的会话管理

### 结论
Agent 相关能力可以分布在多个页，但每页必须只承担一个明确职责，不能再互相复制主体内容。

---

## 3.3 会话 / 最近任务重复

### 当前分布
1. Chat 页右侧最近会话
2. Sessions 页完整会话工作台
3. Agents 页最近会话预览
4. Overview 页 latest task / latest result 摘要

### 问题本质
“最近任务”这一类内容现在有 4 处入口，但信息层级不同、展示粒度不同、交互目标也不同。

这会导致两个问题：
1. 内容重复
2. 用户不知道“继续任务”应该去哪一页做

### 收口建议
- **Chat**：只展示当前 Agent 的最近会话，且只保留 3~5 条
- **Agents**：只展示当前 Agent 的会话摘要预览，作为跳转桥梁
- **Sessions**：唯一完整会话管理页
- **Overview**：只保留一条全局摘要，不再承载任务列表语义

### 结论
任务与会话应该形成“摘要 → 预览 → 完整工作台”的三级信息密度，而不是平级重复。

---

## 3.4 环境信息重复

### 当前分布
1. Setup 页：探测环境
2. Profiles 页：管理 Environment
3. Settings 页：当前 Environment 摘要
4. Overview 页：默认 Environment / Node / Config 摘要
5. Console 页：连接时选择 Environment

### 问题本质
用户对“Environment”这件事的心智是连续的，但产品结构将它分成了多页，并且每页都重复展示一部分相似内容。

### 收口建议
- **Setup**：只处理“发现 / 导入”
- **Profiles**：只处理“编辑 / 校验 / 设默认”
- **Settings**：只保留当前生效 Environment 摘要
- **Overview**：减少环境字段，只保留 readiness 级别概览
- **Console**：只保留连接执行时必需的 Environment 选择控件

### 结论
环境能力可以保留多入口，但每个入口必须对应一个清晰动作：导入、管理、只读摘要、执行选择。

---

## 3.5 日志与过程信息重复

### 当前分布
1. Logs 页：诊断日志
2. Chat 中曾有日志能力
3. Console 页：stdout / stderr 过程输出
4. Sessions 页：任务 transcript
5. Header：issue indicator

### 问题本质
这里实际上混了两类不同信息：

1. **诊断日志**
   - Gateway 连接
   - 握手
   - 请求事件
   - Runtime 诊断

2. **任务执行过程**
   - stdout / stderr
   - transcript
   - 当前任务过程

目前两者边界还不够清楚，因此看起来像“都是日志”。

### 收口建议
- **Logs**：只做系统诊断与连接排障
- **Sessions / Task Detail**：只做任务执行过程
- **Header issue**：只做轻量提醒，不承载详细信息

### 结论
系统诊断与任务过程必须明确拆开，否则用户难以判断问题到底发生在哪一层。

---

## 3.6 Settings 与高级工具重复

### 当前分布
1. 独立 Tab：Setup / Profiles / Console
2. Settings 页内部 Advanced Tools Tab：再次嵌入 Setup / Profiles / Console

### 问题本质
这属于最明显的重复：

> **同一批页面既作为一级导航存在，又被嵌入到 Settings 的二级 Tab 中再次出现。**

这会直接破坏用户对信息架构的信任。

### 收口建议
二选一，不能并存：

#### 方案 A（更推荐）
- Setup / Profiles / Console 保留一级导航
- Settings 中删除 Advanced Tools 嵌入

#### 方案 B
- 一级导航移除 Setup / Profiles / Console
- Settings 成为“偏好 + 高级工具容器”

### 当前阶段建议
基于当前产品越来越复杂，建议采用 **方案 A**：
- 保持一级入口清晰
- Settings 回归设置本身

---

## 3.7 Docs 与 Markdown Test 重复层级问题

### 当前分布
1. Docs：帮助文档
2. Markdown Test：开发调试页

### 问题本质
`Markdown Test` 并不是面向用户的正式产品入口，它属于开发验证能力，不应该长期与 Docs 并列为产品一级入口。

### 收口建议
- Docs 保留一级或资源区入口
- Markdown Test 移入开发模式、调试开关或隐藏入口

---

## 四、一级导航的推荐收口方案

## 推荐一级 Tab

1. Chat
2. Sessions
3. Agents
4. Connect（由当前 Console 演化）
5. Environments（可由 Setup + Profiles 合并重构）
6. Settings
7. Docs

## 建议降级或移出一级导航的内容

1. Overview
   - 降级为首页中的概览段或 Dashboard 子页
2. Logs
   - 并入 Connect / Diagnostics 子 Tab
3. Setup
   - 并入 Environments
4. Profiles
   - 并入 Environments
5. Markdown Test
   - 移入开发调试模式

---

## 五、最终判断

当前项目最大的重复问题，不是组件重复，而是：

> **一级导航正在同时承载“用户任务流、技术工作流、状态摘要、开发调试流”。**

后续收口的核心不是做减法本身，而是重新回答这几个一级问题：

1. 我现在要发起任务吗？→ Chat
2. 我要管理任务历史吗？→ Sessions
3. 我要管理 Agent 吗？→ Agents
4. 我要连接或排障吗？→ Connect
5. 我要管理环境吗？→ Environments
6. 我要改偏好吗？→ Settings
7. 我要看帮助吗？→ Docs

只要一级导航稳定回答这 7 个问题，重复感就会明显下降。
