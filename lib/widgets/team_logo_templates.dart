import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/team_logo.dart';

/// Paints a logo template inside the given rect (centered, with padding).
/// Uses palette fg/accent; stroke weight ~1.5–2 for crisp at 36px.
class TeamLogoTemplatePainter extends CustomPainter {
  TeamLogoTemplatePainter({
    required this.templateId,
    required this.palette,
    this.size = 24.0,
  });

  final String templateId;
  final LogoPalette palette;
  final double size;

  static const double _stroke = 1.8;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final rect = Offset.zero & canvasSize;
    final center = rect.center;
    final half = math.min(rect.width, rect.height) * 0.5 * 0.72;
    final r = half;

    final paintFg = Paint()
      ..color = palette.fg
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final paintAccent = Paint()
      ..color = palette.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fillFg = Paint()..color = palette.fg;

    void circle(Offset c, double radius, {bool fill = false}) {
      if (fill) {
        canvas.drawCircle(c, radius, fillFg);
      } else {
        canvas.drawCircle(c, radius, paintFg);
      }
    }

    void line(Offset a, Offset b) => canvas.drawLine(a, b, paintFg);
    void path(Path p) => canvas.drawPath(p, paintFg);

    switch (templateId) {
      case 'circle_ball':
        circle(center, r * 0.92);
        circle(center, r * 0.35, fill: true);
        path(Path()
          ..moveTo(center.dx - r * 0.35, center.dy)
          ..quadraticBezierTo(
            center.dx - r * 0.2, center.dy - r * 0.5,
            center.dx, center.dy - r * 0.6,
          )
          ..quadraticBezierTo(
            center.dx + r * 0.2, center.dy - r * 0.5,
            center.dx + r * 0.35, center.dy,
          ));
        break;

      case 'shield_star':
        final path = Path();
        path.moveTo(center.dx, center.dy - r);
        path.lineTo(center.dx + r * 0.85, center.dy - r * 0.2);
        path.lineTo(center.dx + r * 0.5, center.dy + r * 0.3);
        path.lineTo(center.dx + r * 0.5, center.dy + r);
        path.lineTo(center.dx, center.dy + r * 0.85);
        path.lineTo(center.dx - r * 0.5, center.dy + r);
        path.lineTo(center.dx - r * 0.5, center.dy + r * 0.3);
        path.lineTo(center.dx - r * 0.85, center.dy - r * 0.2);
        path.close();
        canvas.drawPath(path, paintFg);
        _drawStar(canvas, center, r * 0.35, paintFg, fillFg);
        break;

      case 'rounded_square_court':
        final rr = RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: r * 1.4, height: r * 1.4),
          Radius.circular(r * 0.28),
        );
        canvas.drawRRect(rr, paintFg);
        final inner = r * 0.5;
        canvas.drawLine(
          Offset(center.dx - inner, center.dy),
          Offset(center.dx + inner, center.dy),
          paintFg,
        );
        canvas.drawCircle(center, inner * 0.4, paintFg);
        canvas.drawCircle(Offset(center.dx - inner * 0.7, center.dy), r * 0.12, paintFg);
        canvas.drawCircle(Offset(center.dx + inner * 0.7, center.dy), r * 0.12, paintFg);
        break;

      case 'whistle_min':
        canvas.drawCircle(center, r * 0.4, paintFg);
        canvas.drawLine(
          Offset(center.dx + r * 0.4, center.dy),
          Offset(center.dx + r * 0.85, center.dy - r * 0.2),
          paintFg,
        );
        canvas.drawLine(
          Offset(center.dx + r * 0.85, center.dy - r * 0.2),
          Offset(center.dx + r * 0.75, center.dy + r * 0.15),
          paintFg,
        );
        break;

      case 'trophy_outline':
        path(Path()
          ..moveTo(center.dx - r * 0.6, center.dy + r * 0.7)
          ..lineTo(center.dx - r * 0.5, center.dy + r * 0.3)
          ..lineTo(center.dx - r * 0.5, center.dy - r * 0.2)
          ..lineTo(center.dx - r * 0.35, center.dy - r * 0.5)
          ..lineTo(center.dx, center.dy - r * 0.65)
          ..lineTo(center.dx + r * 0.35, center.dy - r * 0.5)
          ..lineTo(center.dx + r * 0.5, center.dy - r * 0.2)
          ..lineTo(center.dx + r * 0.5, center.dy + r * 0.3)
          ..lineTo(center.dx + r * 0.6, center.dy + r * 0.7));
        line(Offset(center.dx - r * 0.25, center.dy + r * 0.7), Offset(center.dx + r * 0.25, center.dy + r * 0.7));
        line(Offset(center.dx - r * 0.5, center.dy + r * 0.3), Offset(center.dx + r * 0.5, center.dy + r * 0.3));
        break;

      case 'bolt_ball':
        circle(center, r * 0.9);
        final bolt = Path();
        bolt.moveTo(center.dx + r * 0.25, center.dy - r * 0.6);
        bolt.lineTo(center.dx - r * 0.2, center.dy);
        bolt.lineTo(center.dx + r * 0.35, center.dy);
        bolt.lineTo(center.dx - r * 0.25, center.dy + r * 0.6);
        bolt.lineTo(center.dx, center.dy + r * 0.1);
        bolt.lineTo(center.dx - r * 0.35, center.dy + r * 0.1);
        bolt.close();
        canvas.drawPath(bolt, paintAccent);
        break;

      case 'star_ring':
        circle(center, r * 0.88);
        _drawStar(canvas, center, r * 0.5, paintFg, fillFg);
        break;

      case 'pennant':
        final p = Path();
        p.moveTo(center.dx - r * 0.7, center.dy - r * 0.5);
        p.lineTo(center.dx + r * 0.75, center.dy);
        p.lineTo(center.dx - r * 0.7, center.dy + r * 0.5);
        p.close();
        canvas.drawPath(p, paintFg);
        canvas.drawPath(p, Paint()..color = palette.fg.withValues(alpha: 0.2)..style = PaintingStyle.fill);
        break;

      case 'tree_min':
        path(Path()
          ..moveTo(center.dx, center.dy - r * 0.7)
          ..lineTo(center.dx + r * 0.5, center.dy + r * 0.5)
          ..lineTo(center.dx + r * 0.2, center.dy + r * 0.5)
          ..lineTo(center.dx + r * 0.4, center.dy + r * 0.85)
          ..lineTo(center.dx - r * 0.4, center.dy + r * 0.85)
          ..lineTo(center.dx - r * 0.2, center.dy + r * 0.5)
          ..lineTo(center.dx - r * 0.5, center.dy + r * 0.5)
          ..close());
        break;

      case 'paw_min':
        circle(Offset(center.dx, center.dy + r * 0.15), r * 0.32, fill: true);
        circle(Offset(center.dx - r * 0.35, center.dy - r * 0.1), r * 0.2, fill: true);
        circle(Offset(center.dx + r * 0.35, center.dy - r * 0.1), r * 0.2, fill: true);
        circle(Offset(center.dx - r * 0.55, center.dy + r * 0.2), r * 0.18, fill: true);
        circle(Offset(center.dx + r * 0.55, center.dy + r * 0.2), r * 0.18, fill: true);
        break;

      case 'bird_min':
        path(Path()
          ..moveTo(center.dx - r * 0.6, center.dy)
          ..quadraticBezierTo(center.dx - r * 0.2, center.dy - r * 0.5, center.dx + r * 0.5, center.dy - r * 0.15)
          ..quadraticBezierTo(center.dx + r * 0.3, center.dy + r * 0.2, center.dx - r * 0.6, center.dy + r * 0.25)
          ..close());
        path(Path()
          ..moveTo(center.dx + r * 0.5, center.dy - r * 0.15)
          ..quadraticBezierTo(center.dx + r * 0.7, center.dy, center.dx + r * 0.5, center.dy + r * 0.2));
        break;

      case 'bolt_min':
        final bolt = Path();
        bolt.moveTo(center.dx + r * 0.28, center.dy - r * 0.65);
        bolt.lineTo(center.dx - r * 0.22, center.dy);
        bolt.lineTo(center.dx + r * 0.38, center.dy);
        bolt.lineTo(center.dx - r * 0.28, center.dy + r * 0.65);
        bolt.lineTo(center.dx, center.dy + r * 0.12);
        bolt.lineTo(center.dx - r * 0.38, center.dy + r * 0.12);
        bolt.close();
        canvas.drawPath(bolt, paintAccent);
        break;

      case 'flame_min':
        path(Path()
          ..moveTo(center.dx, center.dy - r * 0.75)
          ..quadraticBezierTo(center.dx + r * 0.5, center.dy - r * 0.2, center.dx + r * 0.35, center.dy + r * 0.3)
          ..quadraticBezierTo(center.dx + r * 0.5, center.dy + r * 0.1, center.dx + r * 0.25, center.dy + r * 0.7)
          ..quadraticBezierTo(center.dx, center.dy + r * 0.4, center.dx, center.dy + r * 0.5)
          ..quadraticBezierTo(center.dx, center.dy + r * 0.4, center.dx - r * 0.25, center.dy + r * 0.7)
          ..quadraticBezierTo(center.dx - r * 0.5, center.dy + r * 0.1, center.dx - r * 0.35, center.dy + r * 0.3)
          ..quadraticBezierTo(center.dx - r * 0.5, center.dy - r * 0.2, center.dx, center.dy - r * 0.75));
        break;

      default:
        circle(center, r * 0.5);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double r, Paint stroke, Paint fill) {
    const points = 5;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? r : r * 0.45;
      final angle = -math.pi / 2 + (i * math.pi / points);
      final pt = center + Offset(radius * math.cos(angle), radius * math.sin(angle));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant TeamLogoTemplatePainter oldDelegate) {
    return oldDelegate.templateId != templateId ||
        oldDelegate.palette != palette ||
        oldDelegate.size != size;
  }
}
