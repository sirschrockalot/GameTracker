import 'dart:math' as math;
import 'dart:ui';

/// Logo kind stored on Team.
const String kLogoKindNone = 'none';
const String kLogoKindTemplate = 'template';
const String kLogoKindMonogram = 'monogram';
const String kLogoKindImage = 'image';

/// Template IDs for code-rendered logos (general + mascot).
const List<String> kLogoTemplateIds = [
  'circle_ball',
  'shield_star',
  'rounded_square_court',
  'whistle_min',
  'trophy_outline',
  'bolt_ball',
  'star_ring',
  'pennant',
  'tree_min',
  'paw_min',
  'bird_min',
  'bolt_min',
  'flame_min',
];

/// Mascot template IDs used for name-aware suggestions.
const List<String> kMascotTemplateIds = ['tree_min', 'paw_min', 'bird_min', 'bolt_min', 'flame_min'];

/// Non-mascot template IDs for fill suggestions (excludes mascot set).
const List<String> kFillTemplateIds = [
  'circle_ball',
  'shield_star',
  'rounded_square_court',
  'whistle_min',
  'trophy_outline',
  'bolt_ball',
  'star_ring',
  'pennant',
];

/// Apple-ish palette: bg (circle fill), fg (main icon/text), accent (secondary).
class LogoPalette {
  const LogoPalette({
    required this.id,
    required this.bg,
    required this.fg,
    required this.accent,
  });
  final String id;
  final Color bg;
  final Color fg;
  final Color accent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogoPalette &&
          id == other.id &&
          bg == other.bg &&
          fg == other.fg &&
          accent == other.accent;

  @override
  int get hashCode => Object.hash(id, bg, fg, accent);
}

/// 8 palettes: slate/ice, navy/cyan, emerald/ivory, charcoal/lime, indigo/amber,
/// red/ivory, teal/coral, purple/mint. Modern tones, no neon.
final List<LogoPalette> kLogoPalettes = [
  LogoPalette(
    id: 'slate_ice',
    bg: const Color(0xFF475569),
    fg: const Color(0xFFF1F5F9),
    accent: const Color(0xFF94A3B8),
  ),
  LogoPalette(
    id: 'navy_cyan',
    bg: const Color(0xFF1E3A5F),
    fg: const Color(0xFFE0F2FE),
    accent: const Color(0xFF7DD3FC),
  ),
  LogoPalette(
    id: 'emerald_ivory',
    bg: const Color(0xFF065F46),
    fg: const Color(0xFFFFF9E6),
    accent: const Color(0xFF6EE7B7),
  ),
  LogoPalette(
    id: 'charcoal_lime',
    bg: const Color(0xFF292524),
    fg: const Color(0xFFECFCCB),
    accent: const Color(0xFFBEF264),
  ),
  LogoPalette(
    id: 'indigo_amber',
    bg: const Color(0xFF3730A3),
    fg: const Color(0xFFFEF3C7),
    accent: const Color(0xFFFCD34D),
  ),
  LogoPalette(
    id: 'red_ivory',
    bg: const Color(0xFF991B1B),
    fg: const Color(0xFFFFF9E6),
    accent: const Color(0xFFFCA5A5),
  ),
  LogoPalette(
    id: 'teal_coral',
    bg: const Color(0xFF0F766E),
    fg: const Color(0xFFFED7AA),
    accent: const Color(0xFF5EEAD4),
  ),
  LogoPalette(
    id: 'purple_mint',
    bg: const Color(0xFF5B21B6),
    fg: const Color(0xFFD1FAE5),
    accent: const Color(0xFFA78BFA),
  ),
];

LogoPalette? paletteById(String? id) {
  if (id == null || id.isEmpty) return null;
  try {
    return kLogoPalettes.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
}

/// Stable hash from team name -> palette index -> paletteId.
String paletteForName(String teamName) {
  final s = _sanitizeName(teamName);
  if (s.isEmpty) return kLogoPalettes[0].id;
  var h = 0;
  for (var i = 0; i < s.length; i++) {
    h = 0x1fffffff & (h + s.codeUnitAt(i));
    h = 0x1fffffff & (h + ((h << 10) & 0x1fffffff));
    h ^= h >> 6;
  }
  h = 0x1fffffff & (h + ((h << 3) & 0x1fffffff));
  h ^= h >> 11;
  h = 0x1fffffff & (h + ((h << 15) & 0x1fffffff));
  final index = h % kLogoPalettes.length;
  return kLogoPalettes[index >= 0 ? index : index + kLogoPalettes.length].id;
}

String _sanitizeName(String name) {
  return name
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '');
}

/// Normalize for matching: lowercase, no punctuation/apostrophes, collapse whitespace, tokens; strip trailing 's' for matching.
List<String> _normalizeTokensForMatching(String teamName) {
  final s = _sanitizeName(teamName)
      .toLowerCase()
      .replaceAll(RegExp(r"['\u2019]"), '')
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (s.isEmpty) return [];
  return s.split(' ').map((w) {
    final t = w.trim();
    if (t.length > 1 && t.endsWith('s')) return t.substring(0, t.length - 1);
    return t;
  }).where((t) => t.isNotEmpty).toList();
}

/// Keyword -> mascot templateId. Synonyms listed per category.
const Map<String, String> _mascotKeywords = {
  'tree_min': 'sycamore oak maple pine cedar birch willow timber forest',
  'paw_min': 'tiger lion panther wildcat cougar bobcat wolf husky bulldog hound',
  'bird_min': 'eagle hawk falcon raven',
  'bolt_min': 'thunder lightning storm tornado',
  'flame_min': 'fire flame blaze',
};

/// Score: 2 = exact token match, 1 = substring match. Returns (templateId, score).
List<({String templateId, int score})> _mascotMatches(List<String> tokens) {
  final matches = <String, int>{};
  for (final entry in _mascotKeywords.entries) {
    final templateId = entry.key;
    final keywords = entry.value.split(' ');
    for (final token in tokens) {
      if (token.isEmpty) continue;
      for (final kw in keywords) {
        if (token == kw) {
          matches[templateId] = math.max(matches[templateId] ?? 0, 2);
        } else if (token.contains(kw) || kw.contains(token)) {
          matches[templateId] = math.max(matches[templateId] ?? 0, 1);
        }
      }
    }
  }
  final list = matches.entries.map((e) => (templateId: e.key, score: e.value)).toList();
  list.sort((a, b) => b.score.compareTo(a.score));
  return list;
}

/// Monogram: 1 word -> first letter; 2+ words -> first 2 letters; uppercase, max 2 chars.
String monogramFromTeamName(String teamName) {
  final s = _sanitizeName(teamName);
  if (s.isEmpty) return '?';
  final words = s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.length == 1) {
    return words[0].isNotEmpty ? words[0][0].toUpperCase() : '?';
  }
  final a = words[0].isNotEmpty ? words[0][0].toUpperCase() : '';
  final b = words[1].isNotEmpty ? words[1][0].toUpperCase() : '';
  return (a + b).substring(0, (a.length + b.length).clamp(0, 2));
}

/// One suggestion: either template+palette or monogram (layout variant 0/1).
class LogoSuggestion {
  const LogoSuggestion({
    this.templateId,
    required this.paletteId,
    this.monogramText,
    this.monogramLayout = 0,
    this.recommended = false,
  });
  final String? templateId;
  final String paletteId;
  final String? monogramText;
  final int monogramLayout;
  final bool recommended;
  bool get isMonogram => monogramText != null;
}

/// Name-aware: 8 suggestions. Mascot matches first (1–2, "Recommended"), then fill templates, then 2 monograms.
List<LogoSuggestion> logoSuggestionsForTeamName(String teamName) {
  final sanitized = _sanitizeName(teamName);
  final paletteId = paletteForName(teamName);
  final monogram = monogramFromTeamName(teamName);
  final pal = paletteById(paletteId) ?? kLogoPalettes[0];
  final out = <LogoSuggestion>[];
  final tokens = _normalizeTokensForMatching(teamName);
  final mascotList = _mascotMatches(tokens);
  final usedMascots = <String>{};
  for (final m in mascotList) {
    if (usedMascots.length >= 2) break;
    if (usedMascots.add(m.templateId)) {
      out.add(LogoSuggestion(templateId: m.templateId, paletteId: pal.id, recommended: true));
    }
  }
  var h = sanitized.isEmpty ? 42 : sanitized.codeUnitAt(0);
  final needed = 6 - out.length;
  for (var i = 0; i < needed; i++) {
    final templateIndex = (h + i * 7) % kFillTemplateIds.length;
    out.add(LogoSuggestion(templateId: kFillTemplateIds[templateIndex], paletteId: pal.id));
  }
  out.add(LogoSuggestion(paletteId: paletteId, monogramText: monogram, monogramLayout: 0));
  out.add(LogoSuggestion(paletteId: paletteId, monogramText: monogram, monogramLayout: 1));
  return out;
}
