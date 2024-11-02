import 'dart:math';

class IDGenerator {
  static Random random = Random(DateTime.now().millisecond);
  static String hex = "0123456789abcdef";

  static String generateID() {
    final List<String> idSegments = List.generate(16, (index) => hex[random.nextInt(16)], growable: false);
    return idSegments.join("");
  }
}
