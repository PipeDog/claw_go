# Claw Go

Claw Go 是一款 **macOS 优先** 的桌面 AI 助手应用。  
它面向的不是熟悉 CLI 的技术用户，而是希望直接表达任务目标的普通用户：**用户只需要说“我想做什么”，应用负责在后台完成 Gateway 连接、Agent 选择、任务执行与结果呈现。**

## 应用定位

Claw Go 的核心思路，是把 OpenClaw 的底层能力包装成可视化桌面工作台：

- 隐藏 `CLI / Profile / Session` 等技术概念
- 以“任务”和“对话”作为主要交互入口
- 让用户在 GUI 中完成连接、切换 Agent、查看会话与结果
- 在需要时，仍保留诊断、环境管理和高级配置能力

## 功能概览

当前版本已经围绕以下能力构建了完整的桌面工作流：

### 1. 聊天与任务执行
- 提供主聊天界面，支持直接输入任务
- 支持以对话形式查看任务上下文与执行反馈
- 支持展示任务摘要、结果与过程信息

### 2. Gateway 控制
- 支持启动 Gateway
- 支持重启 Gateway
- 支持连接 Gateway
- 在界面顶部展示版本状态与当前运行状态

### 3. Agent 工作台
- 支持查看 Agent 目录
- 支持选择当前工作 Agent
- 支持在不同 Agent 上发起任务
- 支持围绕 Agent 建立工作区与诊断视图

### 4. 最近会话与任务历史
- 支持查看最近会话
- 支持回看历史任务内容
- 支持从最近会话中恢复工作上下文

### 5. 环境与配置管理
- 支持环境发现与管理
- 支持 Profile / Workspace 相关配置
- 支持基础设置与高级工具入口

### 6. 帮助与诊断
- 提供帮助中心 / 文档入口
- 提供连接、运行状态、日志等技术诊断能力

## 界面预览

下图对应本项目当前桌面端主界面示意，引用自需求中提供的截图 **[Image #1]**：

> 截图展示了 Claw Go 的核心交互形态：左侧为一级导航，中间为聊天与任务执行区，顶部为 Gateway 控制与状态区，右侧为最近会话列表。

## 当前信息架构

应用当前以以下一级功能区组织：

- **聊天**：任务输入与对话执行主入口
- **会话**：任务历史与会话查看
- **Connect**：Gateway 连接与控制
- **Agents**：Agent 目录、工作区、诊断
- **Environments**：环境与配置管理
- **设置**：应用设置与高级工具入口
- **文档**：帮助中心与说明内容

## 保留的底层能力

虽然产品层默认弱化技术细节，但高级工具中仍接入真实 OpenClaw CLI 能力：

- `openclaw configure`
- `openclaw config file`
- `openclaw config validate --json`
- `openclaw gateway status --json`
- `openclaw health --json`
- `openclaw sessions --json`
- `openclaw logs --plain`
- `openclaw onboard --install-daemon`

## 技术栈

- Flutter
- Dart
- Riverpod
- GoRouter
- `path_provider`
- `flutter_secure_storage`
- `flutter_localizations`

## 目录结构

- `lib/app/`：应用入口、主题、路由、主框架
- `lib/business/assistant/`：聊天、任务中心、Agents 等核心业务
- `lib/business/help/`：帮助中心
- `lib/business/settings/`：设置与高级工具容器
- `lib/business/onboarding|workspace|session/`：环境准备、工作区、会话与诊断能力
- `lib/component/`：OpenClaw Runtime 适配层与领域模型
- `lib/foundation/`：进程、存储、基础 ViewModel、通用 UI 与工具
- `prd/`：产品需求、路线图、优化分析文档

## 开发命令

```bash
flutter pub get
flutter analyze
flutter run -d macos
```
