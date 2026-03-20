# Repository Guidelines

## 项目结构与模块组织
本仓库必须严格遵循 Flutter **四层纵向架构**：`app → business → component → foundation`，禁止反向依赖或同级业务互相依赖。

推荐目录：
- `lib/app/`：应用入口、全局配置、路由、根容器
- `lib/business/`：业务模块，按功能拆分，如 `home/`、`user/profile/`
- `lib/component/`：支付、分享、推送、更新等通用功能组件
- `lib/foundation/`：网络、数据库、路由、工具、基础能力

每个业务模块内部必须采用 **MVVM**：`page/`、`view/`、`view_model/`、`model/`、`repository/`。子模块最多嵌套一级。

## 构建、测试与开发命令
常用 Flutter 命令：
- `flutter pub get`：安装依赖
- `flutter analyze`：静态检查，提交前必须通过
- `flutter test`：运行测试
- `flutter run`：本地启动应用

如后续引入脚本，请保持入口统一，例如 `make analyze`、`make test`。

## 编码风格与命名规范
- 使用 Dart 官方格式：`dart format .`
- 文件夹与文件名统一使用 **小写下划线**，如 `home_view_model.dart`
- 类名使用 **大驼峰**，如 `HomeViewModel`
- 变量和方法使用 **小驼峰**，如 `loadUserInfo()`
- 页面文件必须以 `_page.dart` 结尾；页面类必须以 `Page` 结尾
- `view/` 中组件按功能命名，如 `home_item_view.dart`、`home_navigation_bar.dart`
- 禁止使用 `widget` 作为文件或类名后缀
- 注释完善，除非特殊名词外，同时使用中文进行注释
- UI 结构拆分清晰，不要将所有的 UI 全都写在同一个组件中，而应该根据组件的层级进行独立封装，每一个组件尽量占用一个独立的文件当中
- 再次强调，规范、结构清晰、层级分明，是第一要义，必须完全遵守

## MVVM 与组件化约束
- View 仅负责 UI 与事件响应，不写业务逻辑
- ViewModel 是业务逻辑唯一入口，**禁止持有 `BuildContext`**
- Repository 负责网络、本地缓存和数据聚合
- Model 仅定义数据结构，不承载业务行为
- 业务模块之间只允许通过路由通信，不可直接 import

## 测试规范
测试目录建议镜像 `lib/` 结构，示例：`test/business/home/home_view_model_test.dart`。优先为 ViewModel、Repository 编写单元测试；修复缺陷时必须补充回归测试。

## 提交与 PR 规范
提交信息建议使用 Conventional Commits，例如：`feat: add home module scaffold`、`fix: correct profile route`。

PR 必须包含：变更摘要、影响范围、测试结果；涉及 UI 时附截图；涉及新模块时说明其所在层级以及依赖关系是否符合 `app → business → component → foundation`。

## 第一性原理
- 请使用第一性原理思考，不能默认用户一定非常清楚自己想要什么以及应该如何实现。
- 处理需求时，必须从原始问题、目标和动机出发，审慎分析，而不是直接沿用表层表达。
- 如果用户的动机、目标、约束或预期结果不清晰，必须先停下来讨论并澄清，再继续推进实现。

## Flutter 代码规范补充
- 只要需要编写任何 Flutter 代码，必须强制遵循 `flutter-architecture.md` 中定义的 **MVVM + 组件化** 方案规范。
- 若 `AGENTS.md` 与 `flutter-architecture.md` 都涉及 Flutter 架构约束，执行时必须同时满足，且不得绕开 `flutter-architecture.md`。

## 修改 / 重构方案规范
- 当需要给出修改方案或重构方案时，不允许给出兼容性方案、补丁式方案或临时过渡方案。
- 方案必须坚持最短路径实现，避免过度设计，同时不能违反上一条要求。
- 不允许自行扩展到用户未提出的需求范围，不允许附带提供兜底、降级或额外分支方案，以避免业务逻辑偏移。
