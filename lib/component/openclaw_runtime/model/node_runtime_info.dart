/// Node 运行时信息。
class NodeRuntimeInfo {
  const NodeRuntimeInfo({
    required this.requiredVersion,
    this.executablePath,
    this.version,
    this.pathEnvironment,
  });

  final String requiredVersion;
  final String? executablePath;
  final String? version;
  final String? pathEnvironment;

  bool get isDetected => executablePath != null && executablePath!.isNotEmpty;

  bool get isSatisfied {
    if (!isDetected || version == null || version!.isEmpty) {
      return false;
    }
    return _compareVersions(version!, requiredVersion) >= 0;
  }

  String get normalizedVersion {
    if (version == null || version!.isEmpty) {
      return '';
    }
    return version!.startsWith('v') ? version!.substring(1) : version!;
  }

  static int _compareVersions(String left, String right) {
    final List<int> leftParts = _parseParts(left);
    final List<int> rightParts = _parseParts(right);
    final int maxLength = leftParts.length > rightParts.length
        ? leftParts.length
        : rightParts.length;

    for (int index = 0; index < maxLength; index += 1) {
      final int leftValue = index < leftParts.length ? leftParts[index] : 0;
      final int rightValue = index < rightParts.length ? rightParts[index] : 0;
      if (leftValue != rightValue) {
        return leftValue.compareTo(rightValue);
      }
    }
    return 0;
  }

  static List<int> _parseParts(String value) {
    final String normalized =
        value.startsWith('v') ? value.substring(1) : value;
    return normalized
        .split('.')
        .map((String part) => int.tryParse(part) ?? 0)
        .toList();
  }
}
