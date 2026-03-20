/// Markdown 测试样例集合。
///
/// 这里集中维护用于页面验证的固定文本，
/// 方便后续继续补充 case，也避免把大量样例直接堆在页面文件中。
class MarkdownTestFixture {
  const MarkdownTestFixture._();

  /// 页面完整渲染测试文本。
  ///
  /// 覆盖：
  /// - 标题
  /// - 粗体 / 斜体 / 删除线
  /// - 链接文本
  /// - 引用
  /// - 无序 / 有序列表
  /// - 代码块
  static const String fullDocument = r'''
# Markdown 组件测试标题

这是一个用于验证 **粗体**、*斜体*、~~删除线~~、`行内代码` 与 [链接文本](https://example.com) 的综合样例。

> 这是一段引用文本，用来确认引用块的边框、背景和层级是否正常。

## 无序列表示例

- 第一项：普通文本
- 第二项：包含 **粗体强调**
- 第三项：包含 `inline code`

## 有序列表示例

1. 第一步：打开左侧测试入口
2. 第二步：观察标题、正文、引用和代码块
3. 第三步：重点确认代码缩进是否正常

## 代码块示例

```dart
void main() {
  final users = <Map<String, Object>>[
    {
      'name': 'Claw',
      'roles': <String>[
        'assistant',
        'reviewer',
      ],
    },
  ];

  for (final user in users) {
    final List<String> roles =
        user['roles']! as List<String>;
    if (roles.isNotEmpty) {
      print('user=${user['name']}');
    }
  }
}
```
''';

  /// 聊天气泡中的 Markdown 回复示例。
  static const String assistantMessage = r'''
已为你整理结果：

- 当前 **Markdown 组件** 已接入
- 最近会话预览支持 `maxLines`
- 下面这段代码用于重点观察缩进

```json
{
  "name": "Claw",
  "enabled": true,
  "roles": [
    "assistant",
    "reviewer"
  ]
}
```
''';

  /// 用户消息示例。
  static const String userMessage = r'''
请帮我检查：

1. 代码块有没有缩进
2. 列表层级是否清楚
3. `inline code` 是否易读
''';

  /// 最近会话卡片标题示例。
  static const String sessionCardTitle = '修复 **Markdown** 代码块缩进显示';

  /// 最近会话卡片预览示例。
  static const String sessionCardPreview = r'''
已完成初步处理：

- 补充代码块左侧缩进
- 保持 `maxLines` 截断能力
- 待继续观察引用与列表效果
''';

  /// 单独的代码块测试文本。
  ///
  /// 这个样例专门用于肉眼确认多层缩进是否真的展示出来。
  static const String codeOnlyDocument = r'''
```python
def build_tree():
    root = {
        "name": "workspace",
        "children": [
            {
                "name": "app",
                "files": [
                    "main.dart",
                    "root_page.dart",
                ],
            },
            {
                "name": "foundation",
                "files": [
                    "markdown_text_view.dart",
                ],
            },
        ],
    }

    for child in root["children"]:
        print(child["name"])
```
''';
}
