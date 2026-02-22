import 'package:flutter/material.dart';

import '../core/team_logo.dart';
import '../data/isar/models/team.dart';
import 'team_logo_templates.dart';

/// Reusable team logo avatar: circular mask, palette background, template or
/// monogram, subtle border and optional inner highlight (Apple-ish).
class TeamLogoAvatar extends StatelessWidget {
  const TeamLogoAvatar({
    super.key,
    required this.team,
    this.teamNameFallback,
    this.size = 40,
    this.showHighlight = true,
    this.borderOpacity = 0.15,
  })  : palette = null,
        kind = null,
        templateId = null,
        monogramText = null,
        teamName = null;

  /// Preview a suggestion (template or monogram) in the logo picker.
  factory TeamLogoAvatar.forSuggestion({
    Key? key,
    required LogoSuggestion suggestion,
    required String teamName,
    double size = 40,
    bool showHighlight = true,
    double borderOpacity = 0.15,
  }) {
    return TeamLogoAvatar._(
      key: key,
      palette: paletteById(suggestion.paletteId) ?? kLogoPalettes[0],
      kind: suggestion.isMonogram ? kLogoKindMonogram : kLogoKindTemplate,
      templateId: suggestion.templateId,
      monogramText: suggestion.monogramText ?? monogramFromTeamName(teamName),
      teamName: teamName,
      size: size,
      showHighlight: showHighlight,
      borderOpacity: borderOpacity,
    );
  }

  const TeamLogoAvatar._({
    super.key,
    required this.palette,
    required this.kind,
    this.templateId,
    this.monogramText,
    required this.teamName,
    required this.size,
    this.showHighlight = true,
    this.borderOpacity = 0.15,
    Team? team,
  })  : team = team,
        teamNameFallback = null;

  final Team? team;
  final String? teamNameFallback;
  final double size;
  final bool showHighlight;
  final double borderOpacity;

  /// Set when using [TeamLogoAvatar.forSuggestion].
  final LogoPalette? palette;
  final String? kind;
  final String? templateId;
  final String? monogramText;
  final String? teamName;

  @override
  Widget build(BuildContext context) {
    final LogoPalette p;
    final String k;
    final String? tid;
    final String? mono;
    final String name;
    if (team != null) {
      final t = team!;
      name = teamNameFallback ?? t.name;
      p = palette ?? paletteById(t.paletteId) ?? _paletteFromName(name);
      k = t.logoKind ?? 'none';
      tid = t.templateId;
      mono = t.monogramText;
    } else {
      p = palette!;
      k = kind!;
      tid = templateId;
      mono = monogramText;
      name = teamName!;
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: CustomPaint(
          size: Size(size, size),
          painter: _AvatarCirclePainter(
            palette: p,
            borderOpacity: borderOpacity,
            showHighlight: showHighlight,
          ),
          foregroundPainter: _AvatarContentPainter(
            size: size,
            palette: p,
            kind: k,
            templateId: tid,
            monogramText: mono,
            teamName: name,
          ),
        ),
      ),
    );
  }

  LogoPalette _paletteFromName(String name) {
    return paletteById(paletteForName(name)) ?? kLogoPalettes[0];
  }
}

class _AvatarCirclePainter extends CustomPainter {
  _AvatarCirclePainter({
    required this.palette,
    this.borderOpacity = 0.15,
    this.showHighlight = true,
  });

  final LogoPalette palette;
  final double borderOpacity;
  final bool showHighlight;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(center, r, Paint()..color = palette.bg);

    if (showHighlight) {
      final highlight = Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.2, -0.4),
          radius: 1.2,
          colors: [
            Colors.white.withValues(alpha: 0.25),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r));
      canvas.drawCircle(center, r, highlight);
    }

    final border = Paint()
      ..color = Colors.black.withValues(alpha: borderOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, r - 0.5, border);
  }

  @override
  bool shouldRepaint(covariant _AvatarCirclePainter old) {
    return old.palette != palette || old.borderOpacity != borderOpacity || old.showHighlight != showHighlight;
  }
}

class _AvatarContentPainter extends CustomPainter {
  _AvatarContentPainter({
    required this.size,
    required this.palette,
    required this.kind,
    this.templateId,
    this.monogramText,
    required this.teamName,
  });

  final double size;
  final LogoPalette palette;
  final String kind;
  final String? templateId;
  final String? monogramText;
  final String teamName;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (kind == kLogoKindTemplate && templateId != null && templateId!.isNotEmpty) {
      final painter = TeamLogoTemplatePainter(
        templateId: templateId!,
        palette: palette,
        size: this.size * 0.5,
      );
      painter.paint(canvas, rect.size);
      return;
    }
    if (kind == kLogoKindMonogram) {
      final text = (monogramText != null && monogramText!.isNotEmpty)
          ? monogramText!
          : monogramFromTeamName(teamName);
      _paintMonogram(canvas, rect, text);
      return;
    }
    if (kind == kLogoKindImage) {
      // Reserved for future: load image and draw. For now fall through to monogram.
    }
    _paintMonogram(canvas, rect, monogramFromTeamName(teamName));
  }

  void _paintMonogram(Canvas canvas, Rect rect, String text) {
    final center = rect.center;
    final maxRadius = rect.shortestSide / 2 * 0.72;
    final fontSize = (maxRadius * 1.6).clamp(10.0, 24.0);
    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: palette.fg,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
    );
    final tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        center.dx - tp.width / 2,
        center.dy - tp.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarContentPainter old) {
    return old.kind != kind ||
        old.templateId != templateId ||
        old.monogramText != monogramText ||
        old.teamName != teamName ||
        old.size != size ||
        old.palette != palette;
  }
}
