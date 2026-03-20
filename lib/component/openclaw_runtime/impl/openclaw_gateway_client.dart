import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'gateway_chat_protocol.dart';
import '../../../foundation/utils/id_generator.dart';
import '../../../foundation/utils/app_logger.dart';

const List<String> kDefaultGatewayRequestedScopes = <String>[
  'operator.admin',
  'operator.read',
  'operator.write',
  'operator.approvals',
  'operator.pairing',
];

const String kGatewayCompatClientId = 'openclaw-control-ui';
const String kGatewayCompatClientMode = 'webchat';

/// OpenClaw Gateway WebSocket 客户端。
class OpenClawGatewayClient {
  OpenClawGatewayClient({
    required this.url,
    this.token,
    this.password,
  });

  final String url;
  final String? token;
  final String? password;

  final StreamController<OpenClawGatewayEventFrame> _eventController =
      StreamController<OpenClawGatewayEventFrame>.broadcast();
  final Map<String, _PendingGatewayRequest> _pendingRequests =
      <String, _PendingGatewayRequest>{};
  final Completer<void> _doneCompleter = Completer<void>();

  WebSocket? _socket;
  Completer<void>? _connectCompleter;
  bool _connectSent = false;
  bool _closed = false;
  Map<String, dynamic>? _helloPayload;

  Stream<OpenClawGatewayEventFrame> get events => _eventController.stream;
  Future<void> get done => _doneCompleter.future;
  Map<String, dynamic>? get helloPayload => _helloPayload;

  Future<void> connect() async {
    if (_socket != null) {
      return;
    }

    _connectCompleter = Completer<void>();
    AppLogger.info('[gateway] [ws] opening $url');
    final String? originHeader = resolveGatewayOriginHeader(url);
    final WebSocket socket = await WebSocket.connect(
      url,
      headers: <String, dynamic>{
        if (originHeader != null) 'Origin': originHeader,
      },
    );
    _socket = socket;
    socket.listen(
      _handleMessage,
      onError: _handleSocketError,
      onDone: _handleSocketDone,
      cancelOnError: true,
    );

    await _connectCompleter!.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        throw TimeoutException('Gateway 连接握手超时。');
      },
    );
  }

  Future<Map<String, dynamic>?> request(
    String method,
    Map<String, dynamic> params, {
    Duration? timeout,
  }) async {
    final WebSocket? socket = _socket;
    if (socket == null || socket.readyState != WebSocket.open) {
      throw StateError('Gateway 尚未连接。');
    }

    final String requestId = IdGenerator.next('gw');
    final Completer<Map<String, dynamic>?> completer =
        Completer<Map<String, dynamic>?>();
    final Timer? timer = timeout == null
        ? null
        : Timer(timeout, () {
            _pendingRequests.remove(requestId);
            if (!completer.isCompleted) {
              completer.completeError(
                TimeoutException('Gateway 请求超时：$method'),
              );
            }
          });

    _pendingRequests[requestId] = _PendingGatewayRequest(
      completer: completer,
      timer: timer,
      method: method,
      startedAt: DateTime.now(),
    );

    AppLogger.info('[gateway] [ws] ⇢ req $method id=$requestId');

    socket.add(
      jsonEncode(
        <String, dynamic>{
          'type': 'req',
          'id': requestId,
          'method': method,
          'params': params,
        },
      ),
    );

    return completer.future;
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;

    final WebSocket? socket = _socket;
    _socket = null;
    if (socket != null) {
      try {
        await socket.close();
      } catch (_) {
        // 忽略关闭异常。
      }
    }

    _failAllPending(StateError('Gateway 连接已关闭。'));
    if (!_eventController.isClosed) {
      await _eventController.close();
    }
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.complete();
    }
  }

  void _handleMessage(dynamic rawData) {
    try {
      final Object? decoded = jsonDecode(rawData.toString());
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final String type = decoded['type']?.toString() ?? '';
      if (type == 'event') {
        final OpenClawGatewayEventFrame event =
            OpenClawGatewayEventFrame.fromJson(decoded);
        if (event.event == 'connect.challenge') {
          AppLogger.info('[gateway] [ws] ⇠ event connect.challenge');
          _sendConnect(event.payload);
          return;
        }
        AppLogger.info(
          '[gateway] [ws] ⇠ event ${event.event}'
          '${summarizeGatewayEventPayload(event.payload)}',
        );
        if (!_eventController.isClosed) {
          _eventController.add(event);
        }
        return;
      }

      if (type == 'res') {
        final String requestId = decoded['id']?.toString() ?? '';
        final _PendingGatewayRequest? pending =
            _pendingRequests.remove(requestId);
        if (pending == null) {
          return;
        }
        pending.timer?.cancel();

        final bool ok = decoded['ok'] == true;
        final int elapsedMs =
            DateTime.now().difference(pending.startedAt).inMilliseconds;
        if (ok) {
          final Object? payload = decoded['payload'];
          AppLogger.info(
            '[gateway] [ws] ⇄ res ✓ ${pending.method} ${elapsedMs}ms id=$requestId',
          );
          if (pending.method == 'connect' && payload is Map<String, dynamic>) {
            _helloPayload = payload;
            final List<String> scopes = _extractGrantedScopes(payload);
            if (scopes.isNotEmpty) {
              AppLogger.info(
                '[gateway] [ws] granted scopes: ${scopes.join(', ')}',
              );
            }
          }
          if (payload is Map<String, dynamic>) {
            pending.completer.complete(payload);
          } else {
            pending.completer.complete(null);
          }
        } else {
          final Map<String, dynamic>? error =
              decoded['error'] as Map<String, dynamic>?;
          final String errorCode = error?['code']?.toString().trim() ?? '';
          final String errorMessage =
              error?['message']?.toString() ?? 'Gateway 请求失败。';
          AppLogger.info(
            '[gateway] [ws] ⇄ res ✗ ${pending.method} ${elapsedMs}ms '
            'errorCode=${errorCode.isEmpty ? 'UNKNOWN' : errorCode} '
            'errorMessage=$errorMessage id=$requestId',
          );
          pending.completer.completeError(
            OpenClawGatewayRequestError(
              errorMessage,
              code: errorCode.isEmpty ? null : errorCode,
            ),
          );
        }
      }
    } catch (_) {
      // 忽略无法解析的帧。
    }
  }

  void _sendConnect(Map<String, dynamic>? payload) {
    if (_connectSent) {
      return;
    }

    final String nonce = payload?['nonce']?.toString().trim() ?? '';
    if (nonce.isEmpty) {
      final StateError error = StateError('Gateway 未返回有效 nonce。');
      if (!(_connectCompleter?.isCompleted ?? true)) {
        _connectCompleter?.completeError(error);
      }
      unawaited(close());
      return;
    }

    _connectSent = true;
    final Map<String, dynamic> params = buildGatewayConnectParams(
      token: token,
      password: password,
    );
    request(
      'connect',
      params,
      timeout: const Duration(seconds: 8),
    ).then((_) {
      if (!(_connectCompleter?.isCompleted ?? true)) {
        _connectCompleter?.complete();
      }
    }).catchError((Object error, StackTrace _) {
      if (!(_connectCompleter?.isCompleted ?? true)) {
        _connectCompleter?.completeError(error);
      }
      unawaited(close());
    });
  }

  void _handleSocketError(Object error) {
    final Exception exception =
        error is Exception ? error : Exception(error.toString());
    AppLogger.info('[gateway] [ws] socket error: $exception');
    if (!(_connectCompleter?.isCompleted ?? true)) {
      _connectCompleter?.completeError(exception);
    }
    _failAllPending(exception);
    unawaited(close());
  }

  void _handleSocketDone() {
    final StateError error = StateError('Gateway WebSocket 已断开。');
    AppLogger.info('[gateway] [ws] socket closed');
    if (!(_connectCompleter?.isCompleted ?? true)) {
      _connectCompleter?.completeError(error);
    }
    _failAllPending(error);
    unawaited(close());
  }

  void _failAllPending(Object error) {
    for (final _PendingGatewayRequest pending in _pendingRequests.values) {
      pending.timer?.cancel();
      if (!pending.completer.isCompleted) {
        pending.completer.completeError(error);
      }
    }
    _pendingRequests.clear();
  }

  static Map<String, dynamic> buildGatewayConnectParams({
    String? token,
    String? password,
  }) {
    return <String, dynamic>{
      'minProtocol': 3,
      'maxProtocol': 3,
      'client': <String, dynamic>{
        'id': kGatewayCompatClientId,
        'displayName': 'ClawGo',
        'version': '0.1.0',
        'platform': Platform.operatingSystem,
        'deviceFamily': 'desktop',
        'mode': kGatewayCompatClientMode,
      },
      'caps': const <String>['tool-events'],
      'role': 'operator',
      'scopes': kDefaultGatewayRequestedScopes,
      if ((token ?? '').trim().isNotEmpty || (password ?? '').trim().isNotEmpty)
        'auth': <String, dynamic>{
          if ((token ?? '').trim().isNotEmpty) 'token': token!.trim(),
          if ((password ?? '').trim().isNotEmpty) 'password': password!.trim(),
        },
      'userAgent': 'ClawGo/0.1.0 (${Platform.operatingSystem})',
      'locale': Platform.localeName,
    };
  }

  static String? resolveGatewayOriginHeader(String wsUrl) {
    final Uri? uri = Uri.tryParse(wsUrl);
    if (uri == null || uri.host.trim().isEmpty) {
      return null;
    }
    final String scheme = switch (uri.scheme) {
      'wss' => 'https',
      _ => 'http',
    };
    final String portSuffix = uri.hasPort ? ':${uri.port}' : '';
    return '$scheme://${uri.host}$portSuffix';
  }

  List<String> _extractGrantedScopes(Map<String, dynamic>? helloPayload) {
    final Map<String, dynamic>? auth =
        helloPayload?['auth'] as Map<String, dynamic>?;
    final List<dynamic> rawScopes = auth?['scopes'] as List<dynamic>? ??
        helloPayload?['scopes'] as List<dynamic>? ??
        <dynamic>[];
    return rawScopes
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toList();
  }
}

class OpenClawGatewayEventFrame {
  const OpenClawGatewayEventFrame({
    required this.event,
    this.payload,
    this.seq,
  });

  factory OpenClawGatewayEventFrame.fromJson(Map<String, dynamic> json) {
    return OpenClawGatewayEventFrame(
      event: json['event']?.toString() ?? '',
      payload: json['payload'] as Map<String, dynamic>?,
      seq: json['seq'] as int?,
    );
  }

  final String event;
  final Map<String, dynamic>? payload;
  final int? seq;
}

class OpenClawGatewayRequestError implements Exception {
  const OpenClawGatewayRequestError(
    this.message, {
    this.code,
  });

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class _PendingGatewayRequest {
  const _PendingGatewayRequest({
    required this.completer,
    required this.timer,
    required this.method,
    required this.startedAt,
  });

  final Completer<Map<String, dynamic>?> completer;
  final Timer? timer;
  final String method;
  final DateTime startedAt;
}
