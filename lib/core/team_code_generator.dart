import 'dart:math';

/// Generates 6–8 char uppercase codes, excluding ambiguous chars (0, O, 1, I).
class TeamCodeGenerator {
  TeamCodeGenerator._();

  static const int _minLength = 6;
  static const int _maxLength = 8;

  /// Uppercase alphanumeric excluding 0, O, 1, I.
  static const String _chars =
      'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0,O,1,I

  static final Random _random = Random();

  /// Returns a new code of length 6–8 (random length in that range).
  static String generate() {
    final length = _minLength + _random.nextInt(_maxLength - _minLength + 1);
    return List.generate(length, (_) => _chars[_random.nextInt(_chars.length)]).join();
  }
}
