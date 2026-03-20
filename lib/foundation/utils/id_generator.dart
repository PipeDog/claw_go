import 'dart:math';

/// 本地 ID 生成器。
class IdGenerator {
  const IdGenerator._();

  static final Random _random = Random();

  static String next(String prefix) {
    final int timestamp = DateTime.now().microsecondsSinceEpoch;
    final int randomValue = _random.nextInt(1 << 20);
    return '$prefix-$timestamp-$randomValue';
  }
}
