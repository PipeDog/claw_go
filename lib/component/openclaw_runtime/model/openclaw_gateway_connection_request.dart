/// Gateway 连接请求。
///
/// 该模型用于承接“用户在界面中临时输入的连接覆盖项”，
/// 例如 WebSocket 地址、Token、Password。
///
/// 设计上采用可选字段，而不是强制全部填写：
/// - 若字段为空，则回退到当前 Profile / 配置文件 / 环境变量的自动检测结果；
/// - 若字段有值，则优先使用用户输入。
class OpenClawGatewayConnectionRequest {
  const OpenClawGatewayConnectionRequest({
    this.url,
    this.token,
    this.password,
  });

  final String? url;
  final String? token;
  final String? password;

  String? get normalizedUrl => _normalize(url);
  String? get normalizedToken => _normalize(token);
  String? get normalizedPassword => _normalize(password);

  bool get hasOverrides =>
      normalizedUrl != null ||
      normalizedToken != null ||
      normalizedPassword != null;

  static String? _normalize(String? value) {
    final String trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
