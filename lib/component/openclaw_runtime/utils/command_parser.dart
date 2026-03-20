/// 命令参数解析器。
class CommandParser {
  const CommandParser._();

  static List<String> parseArguments(String value) {
    final List<String> arguments = <String>[];
    final StringBuffer buffer = StringBuffer();
    bool inSingleQuotes = false;
    bool inDoubleQuotes = false;
    bool isEscaping = false;

    for (int index = 0; index < value.length; index += 1) {
      final String character = value[index];

      if (isEscaping) {
        buffer.write(character);
        isEscaping = false;
        continue;
      }

      if (character == '\\') {
        isEscaping = true;
        continue;
      }

      if (character == "'" && !inDoubleQuotes) {
        inSingleQuotes = !inSingleQuotes;
        continue;
      }

      if (character == '"' && !inSingleQuotes) {
        inDoubleQuotes = !inDoubleQuotes;
        continue;
      }

      if (RegExp(r'\s').hasMatch(character) &&
          !inSingleQuotes &&
          !inDoubleQuotes) {
        if (buffer.isNotEmpty) {
          arguments.add(buffer.toString());
          buffer.clear();
        }
        continue;
      }

      buffer.write(character);
    }

    if (buffer.isNotEmpty) {
      arguments.add(buffer.toString());
    }

    return arguments;
  }

  static String quoteArgument(String value) {
    final String escaped = value.replaceAll('\\', r'\\').replaceAll('"', r'\"');
    return '"$escaped"';
  }
}
