import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 安全存储 Provider。
final secureStorageServiceProvider = Provider<SecureStorageService>((Ref ref) {
  return SecureStorageService();
});

/// 安全存储服务。
///
/// macOS 下优先写入 Keychain；若环境受限，则回退到内存缓存，
/// 避免在开发或测试场景下直接抛异常影响主流程。
class SecureStorageService {
  SecureStorageService() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static final Map<String, String> _memoryFallback = <String, String>{};

  Future<void> write({required String key, required String? value}) async {
    try {
      if (value == null || value.isEmpty) {
        await _storage.delete(key: key);
        _memoryFallback.remove(key);
        return;
      }
      await _storage.write(key: key, value: value);
    } catch (_) {
      if (value == null || value.isEmpty) {
        _memoryFallback.remove(key);
      } else {
        _memoryFallback[key] = value;
      }
    }
  }

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return _memoryFallback[key];
    }
  }
}
