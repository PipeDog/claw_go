# Claw Go

Claw Go 是一个 **macOS 优先** 的桌面 AI 助手，目标不是让普通用户理解 CLI、Profile、Session 这些技术概念，而是让用户直接说出“想完成什么任务”，再由应用在后台调用 OpenClaw 完成处理。

## 当前产品方向

- 主信息架构：**首页 / 我的任务 / 帮助中心 / 设置**
- 默认隐藏技术细节，仅在 **设置 > 高级工具** 中展示环境准备、工作配置和详细日志
- 首页采用 **大输入框 + 常用动作卡** 入口
- 任务结果页以“任务摘要 + 可展开过程”方式展示，不强迫用户面对底层输出

## 保留的底层能力

高级工具中仍接入真实 OpenClaw CLI 命令：

- `openclaw configure`
- `openclaw config file`
- `openclaw config validate --json`
- `openclaw gateway status --json`
- `openclaw health --json`
- `openclaw sessions --json`
- `openclaw logs --plain`
- `openclaw onboard --install-daemon`

## 目录结构

- `lib/app/`：应用入口、主题、路由、主框架
- `lib/business/assistant/`：首页、任务历史、快捷动作、任务中心状态
- `lib/business/help/`：帮助中心
- `lib/business/settings/`：基础设置与高级工具容器
- `lib/business/onboarding|workspace|session/`：高级工具中的技术能力页面
- `lib/component/`：OpenClaw Runtime 适配层与领域模型
- `lib/foundation/`：进程、存储、基础视图模型、通用面板与工具

## 开发命令

```bash
flutter pub get
flutter analyze
flutter run -d macos
```
