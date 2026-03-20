/// Gateway WebSocket 连接阶段。
enum OpenClawGatewayConnectionPhase {
  disconnected,
  connecting,
  connected,
  error,
}

/// Gateway WebSocket 连接状态。
class OpenClawGatewayConnectionState {
  const OpenClawGatewayConnectionState({
    required this.phase,
    required this.message,
    this.url,
    this.grantedScopes = const <String>[],
  });

  const OpenClawGatewayConnectionState.disconnected({
    this.message = 'Gateway 未连接',
    this.url,
    this.grantedScopes = const <String>[],
  }) : phase = OpenClawGatewayConnectionPhase.disconnected;

  final OpenClawGatewayConnectionPhase phase;
  final String message;
  final String? url;
  final List<String> grantedScopes;

  bool get isConnected => phase == OpenClawGatewayConnectionPhase.connected;

  bool get isConnecting => phase == OpenClawGatewayConnectionPhase.connecting;
}
