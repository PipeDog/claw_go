/// Gateway 连接偏好。
///
/// 用于保存“可安全记忆”的连接信息：
/// - WebSocket URL：明文保存在本地设置 JSON 中；
/// - Gateway Token：由 Repository 写入安全存储；
///
/// Password 明确不在此模型中持久化，只在单次连接时临时使用。
class GatewayConnectionPreferences {
  const GatewayConnectionPreferences({
    this.webSocketUrl,
    this.gatewayToken,
  });

  final String? webSocketUrl;
  final String? gatewayToken;

  bool get isEmpty =>
      _normalize(webSocketUrl) == null && _normalize(gatewayToken) == null;

  GatewayConnectionPreferences copyWith({
    String? webSocketUrl,
    String? gatewayToken,
    bool clearWebSocketUrl = false,
    bool clearGatewayToken = false,
  }) {
    return GatewayConnectionPreferences(
      webSocketUrl:
          clearWebSocketUrl ? null : webSocketUrl ?? this.webSocketUrl,
      gatewayToken:
          clearGatewayToken ? null : gatewayToken ?? this.gatewayToken,
    );
  }

  String? get normalizedWebSocketUrl => _normalize(webSocketUrl);
  String? get normalizedGatewayToken => _normalize(gatewayToken);

  static String? _normalize(String? value) {
    final String trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
