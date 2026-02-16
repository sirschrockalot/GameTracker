/// Validation and sanitization for join-request coachName and note (UI + repo defense in depth).
class JoinRequestValidators {
  JoinRequestValidators._();

  static const int coachNameMinLength = 2;
  static const int coachNameMaxLength = 40;
  static const int noteMaxLength = 80;

  /// Strip control characters (U+0000..U+001F except space, U+007F) and collapse runs of whitespace to a single space, then trim.
  static String _stripControlAndCollapseWhitespace(String s) {
    if (s.isEmpty) return s;
    final buffer = StringBuffer();
    bool lastWasSpace = true;
    for (final rune in s.runes) {
      if (rune < 32 && rune != 0x20) continue;
      if (rune == 0x7F) continue; // DEL
      if (rune == 0x20 || rune == 0x0A || rune == 0x09 || rune == 0x0D) {
        if (!lastWasSpace) {
          buffer.writeCharCode(0x20);
          lastWasSpace = true;
        }
      } else {
        buffer.writeCharCode(rune);
        lastWasSpace = false;
      }
    }
    return buffer.toString().trim();
  }

  /// Sanitize coachName (strip control chars, collapse whitespace). Use in UI and repo.
  static String sanitizeCoachName(String input) {
    return _stripControlAndCollapseWhitespace(input);
  }

  /// Sanitize note (optional). Returns null if empty after sanitize; otherwise truncated to [noteMaxLength].
  static String? sanitizeNote(String? input) {
    if (input == null) return null;
    final s = _stripControlAndCollapseWhitespace(input);
    if (s.isEmpty) return null;
    if (s.length > noteMaxLength) return s.substring(0, noteMaxLength);
    return s;
  }

  /// Validate coachName: required, length 2..40. Returns sanitized value or error message.
  static ({String? value, String? error}) validateCoachName(String raw) {
    final s = sanitizeCoachName(raw);
    if (s.length < coachNameMinLength) {
      return (value: null, error: 'Name must be at least $coachNameMinLength characters');
    }
    if (s.length > coachNameMaxLength) {
      return (value: null, error: 'Name must be at most $coachNameMaxLength characters');
    }
    return (value: s, error: null);
  }

  /// Validate note: optional, length <= 80. Returns sanitized value or null.
  static String? validateNote(String? raw) => sanitizeNote(raw);

  /// Repository-layer enforcement: sanitize and clamp coachName; reject if too short.
  static String enforceCoachNameForPersist(String raw) {
    final s = sanitizeCoachName(raw);
    if (s.length > coachNameMaxLength) return s.substring(0, coachNameMaxLength);
    return s;
  }

  /// Repository-layer enforcement: sanitize and clamp note.
  static String? enforceNoteForPersist(String? raw) => sanitizeNote(raw);
}
