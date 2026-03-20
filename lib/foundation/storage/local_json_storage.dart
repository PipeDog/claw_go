import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/config/app_config.dart';

/// 本地 JSON 存储 Provider。
final localJsonStorageProvider = Provider<LocalJsonStorage>((Ref ref) {
  return LocalJsonStorage();
});

/// 负责把配置写入应用支持目录。
class LocalJsonStorage {
  LocalJsonStorage({Future<Directory> Function()? baseDirectoryResolver})
      : _baseDirectoryResolver = baseDirectoryResolver;

  final Future<Directory> Function()? _baseDirectoryResolver;
  Future<void> _pendingWrite = Future<void>.value();

  Future<Map<String, dynamic>> readJson(String fileName) async {
    final File file = await _resolveFile(fileName);
    if (!file.existsSync()) {
      return <String, dynamic>{};
    }

    final String content = await file.readAsString();
    if (content.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final String normalizedContent = normalizeJsonDocument(content) ?? content;
    final Object? decoded = jsonDecode(normalizedContent);
    if (decoded is Map<String, dynamic>) {
      if (normalizedContent != content) {
        await file.writeAsString(normalizedContent, flush: true);
      }
      return Map<String, dynamic>.from(decoded);
    }

    return <String, dynamic>{};
  }

  Future<void> writeJson(String fileName, Map<String, dynamic> data) async {
    _pendingWrite = _pendingWrite.catchError((Object _) {}).then((_) async {
      final File file = await _resolveFile(fileName);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
        flush: true,
      );
    });
    await _pendingWrite;
  }

  Future<File> _resolveFile(String fileName) async {
    final Directory baseDirectory = await _resolveBaseDirectory();
    if (!baseDirectory.existsSync()) {
      await baseDirectory.create(recursive: true);
    }
    return File('${baseDirectory.path}/$fileName');
  }

  Future<Directory> _resolveBaseDirectory() async {
    if (_baseDirectoryResolver != null) {
      return _baseDirectoryResolver();
    }
    try {
      final Directory supportDirectory = await getApplicationSupportDirectory();
      final String normalizedName =
          AppConfig.appName.toLowerCase().replaceAll(' ', '_');
      return Directory('${supportDirectory.path}/$normalizedName');
    } catch (_) {
      return Directory('${Directory.systemTemp.path}/claw_go');
    }
  }

  /// 尝试从包含尾部脏数据的文本中恢复首个完整 JSON 文档。
  ///
  /// 例如文件尾部多出一个 `}` 时，会仅保留前面的完整对象。
  static String? normalizeJsonDocument(String content) {
    final String trimmed = content.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    try {
      jsonDecode(trimmed);
      return trimmed;
    } on FormatException {
      // 继续尝试恢复。
    }

    final String firstCharacter = trimmed.substring(0, 1);
    if (firstCharacter != '{' && firstCharacter != '[') {
      return null;
    }

    int objectDepth = 0;
    int arrayDepth = 0;
    bool inString = false;
    bool escaped = false;

    for (int index = 0; index < trimmed.length; index += 1) {
      final String character = trimmed[index];
      if (inString) {
        if (escaped) {
          escaped = false;
          continue;
        }
        if (character == r'\') {
          escaped = true;
          continue;
        }
        if (character == '"') {
          inString = false;
        }
        continue;
      }

      if (character == '"') {
        inString = true;
      } else if (character == '{') {
        objectDepth += 1;
      } else if (character == '}') {
        objectDepth -= 1;
      } else if (character == '[') {
        arrayDepth += 1;
      } else if (character == ']') {
        arrayDepth -= 1;
      }

      if (objectDepth == 0 && arrayDepth == 0) {
        final String candidate = trimmed.substring(0, index + 1);
        try {
          jsonDecode(candidate);
          return candidate;
        } on FormatException {
          // 继续向后扫描。
        }
      }
    }

    return null;
  }
}
