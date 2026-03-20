/// Gateway chat 协议辅助工具。
///
/// 这里抽离出事件匹配与日志摘要逻辑，便于回归测试。
class GatewayChatEventPayload {
  const GatewayChatEventPayload({
    required this.sessionKey,
    required this.runId,
    required this.state,
    this.message,
  });

  factory GatewayChatEventPayload.fromJson(Map<String, dynamic>? json) {
    return GatewayChatEventPayload(
      sessionKey: json?['sessionKey']?.toString().trim() ?? '',
      runId: json?['runId']?.toString().trim() ?? '',
      state: json?['state']?.toString().trim() ?? '',
      message: json?['message'],
    );
  }

  final String sessionKey;
  final String runId;
  final String state;
  final Object? message;
}

bool shouldAcceptGatewayChatEvent({
  required String sessionKey,
  required String requestRunId,
  String? responseRunId,
  required GatewayChatEventPayload payload,
}) {
  if (!isEquivalentGatewaySessionKey(
    expectedSessionKey: sessionKey,
    actualSessionKey: payload.sessionKey,
  )) {
    return false;
  }

  final Set<String> acceptedRunIds = <String>{
    requestRunId.trim(),
    responseRunId?.trim() ?? '',
  }..removeWhere((String value) => value.isEmpty);

  if (payload.runId.isNotEmpty &&
      acceptedRunIds.isNotEmpty &&
      !acceptedRunIds.contains(payload.runId)) {
    return payload.state == 'final';
  }

  return true;
}

bool isEquivalentGatewaySessionKey({
  required String expectedSessionKey,
  required String actualSessionKey,
}) {
  final String normalizedExpected = expectedSessionKey.trim();
  final String normalizedActual = actualSessionKey.trim();
  if (normalizedExpected.isEmpty || normalizedActual.isEmpty) {
    return false;
  }

  if (normalizedExpected == normalizedActual) {
    return true;
  }

  final _GatewaySessionAlias? expectedAlias =
      _GatewaySessionAlias.tryParse(normalizedExpected);
  final _GatewaySessionAlias? actualAlias =
      _GatewaySessionAlias.tryParse(normalizedActual);

  if (expectedAlias != null && actualAlias != null) {
    return expectedAlias == actualAlias;
  }

  if (actualAlias != null && actualAlias.matchesShortKey(normalizedExpected)) {
    return true;
  }

  if (expectedAlias != null &&
      expectedAlias.matchesShortKey(normalizedActual)) {
    return true;
  }

  return false;
}

String summarizeGatewayEventPayload(Map<String, dynamic>? payload) {
  if (payload == null || payload.isEmpty) {
    return '';
  }

  final List<String> segments = <String>[];
  final String sessionKey = payload['sessionKey']?.toString().trim() ?? '';
  final String runId = payload['runId']?.toString().trim() ?? '';
  final String state = payload['state']?.toString().trim() ?? '';
  if (sessionKey.isNotEmpty) {
    segments.add('sessionKey=$sessionKey');
  }
  if (runId.isNotEmpty) {
    segments.add('runId=$runId');
  }
  if (state.isNotEmpty) {
    segments.add('state=$state');
  }

  final String preview = _extractMessagePreview(payload['message']);
  if (preview.isNotEmpty) {
    segments.add('message=$preview');
  }

  return segments.isEmpty ? '' : ' ${segments.join(' ')}';
}

String _extractMessagePreview(Object? message) {
  String? text;
  if (message is String) {
    text = message.trim();
  } else if (message is Map<String, dynamic>) {
    final String directText = message['text']?.toString().trim() ?? '';
    if (directText.isNotEmpty) {
      text = directText;
    } else if (message['content'] is String) {
      text = message['content']?.toString().trim();
    }
  }

  if (text == null || text.isEmpty) {
    return '';
  }

  const int maxLength = 48;
  if (text.length <= maxLength) {
    return text.replaceAll('\n', ' ');
  }
  return '${text.substring(0, maxLength).replaceAll('\n', ' ')}…';
}

class _GatewaySessionAlias {
  const _GatewaySessionAlias({
    required this.namespace,
    required this.primaryKey,
    required this.secondaryKey,
  });

  static _GatewaySessionAlias? tryParse(String value) {
    final List<String> segments =
        value.split(':').map((String item) => item.trim()).toList();
    if (segments.length < 3) {
      return null;
    }
    return _GatewaySessionAlias(
      namespace: segments.first,
      primaryKey: segments[1],
      secondaryKey: segments.sublist(2).join(':'),
    );
  }

  final String namespace;
  final String primaryKey;
  final String secondaryKey;

  bool matchesShortKey(String shortKey) {
    final String normalizedShortKey = shortKey.trim();
    if (normalizedShortKey.isEmpty) {
      return false;
    }
    return primaryKey == normalizedShortKey &&
        secondaryKey == normalizedShortKey;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _GatewaySessionAlias &&
        other.namespace == namespace &&
        other.primaryKey == primaryKey &&
        other.secondaryKey == secondaryKey;
  }

  @override
  int get hashCode => Object.hash(namespace, primaryKey, secondaryKey);
}
