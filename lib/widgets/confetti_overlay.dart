import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Shows a full-screen celebration overlay (random effect), then calls [onComplete].
void showConfettiOverlay(
  BuildContext context, {
  required VoidCallback onComplete,
  Duration? duration,
  CelebrationEffect? effect,
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    builder: (context) => ConfettiOverlay(
      duration: duration ?? const Duration(milliseconds: 2500),
      effect: effect,
      onComplete: () {
        if (context.mounted) Navigator.of(context).pop();
        onComplete();
      },
    ),
  );
}

/// Which celebration effect to show (randomly chosen when not specified).
enum CelebrationEffect {
  confetti,
  balloons,
  lasers,
  fireworks,
}

/// Full-screen celebration overlay. Calls [onComplete] when the animation finishes.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    super.key,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 2500),
    this.effect,
  });

  final VoidCallback onComplete;
  final Duration duration;
  final CelebrationEffect? effect;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late CelebrationEffect _effect;
  List<_Particle> _confettiParticles = [];
  List<_Balloon> _balloons = [];
  List<_FireworkBurst> _fireworkBursts = [];
  final Random _random = Random();

  static const _colors = [
    AppColors.primaryOrange,
    AppColors.onCourtGreen,
    AppColors.saveAwardsGold,
    Color(0xFFE07C3A),
    Color(0xFF4A90D9),
    Colors.white,
    Color(0xFFF4A261),
  ];

  @override
  void initState() {
    super.initState();
    _effect = widget.effect ??
        CelebrationEffect.values[_random.nextInt(CelebrationEffect.values.length)];
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);
    if (_confettiParticles.isEmpty && _effect == CelebrationEffect.confetti) {
      _confettiParticles = List.generate(70, (_) => _createConfettiParticle(size));
    }
    if (_balloons.isEmpty && _effect == CelebrationEffect.balloons) {
      _balloons = List.generate(25, (_) => _createBalloon(size));
    }
    if (_fireworkBursts.isEmpty && _effect == CelebrationEffect.fireworks) {
      _fireworkBursts = _createFireworkBursts(size);
    }
  }

  _Particle _createConfettiParticle(Size size) {
    final w = size.width;
    return _Particle(
      x: _random.nextDouble() * w,
      y: _random.nextDouble() * -80 - 20,
      color: _colors[_random.nextInt(_colors.length)],
      size: 4 + _random.nextDouble() * 6,
      drift: (_random.nextDouble() - 0.5) * 80,
      speed: 0.7 + _random.nextDouble() * 0.6,
      wobble: 2 + _random.nextDouble() * 3,
      rotationSpeed: (_random.nextDouble() - 0.5) * 12,
    );
  }

  _Balloon _createBalloon(Size size) {
    return _Balloon(
      x: _random.nextDouble() * size.width,
      y: size.height + 20 + _random.nextDouble() * 40,
      color: _colors[_random.nextInt(_colors.length)],
      radius: 12 + _random.nextDouble() * 14,
      riseSpeed: 0.5 + _random.nextDouble() * 0.5,
      drift: (_random.nextDouble() - 0.5) * 40,
      wobble: 3 + _random.nextDouble() * 4,
    );
  }

  List<_FireworkBurst> _createFireworkBursts(Size size) {
    final bursts = <_FireworkBurst>[];
    final count = 4 + _random.nextInt(3);
    for (var i = 0; i < count; i++) {
      bursts.add(_FireworkBurst(
        x: size.width * (0.2 + _random.nextDouble() * 0.6),
        y: size.height * (0.25 + _random.nextDouble() * 0.35),
        startTime: i * 0.18 + _random.nextDouble() * 0.1,
        particleCount: 35 + _random.nextInt(25),
        color: _colors[_random.nextInt(_colors.length)],
        random: _random,
      ));
    }
    return bursts;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return IgnorePointer(
      child: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _CelebrationPainter(
                progress: _controller.value,
                effect: _effect,
                size: size,
                confettiParticles: _confettiParticles,
                balloons: _balloons,
                fireworkBursts: _fireworkBursts,
              ),
              size: size,
            );
          },
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.drift,
    required this.speed,
    required this.wobble,
    required this.rotationSpeed,
  });

  final double x, y;
  final Color color;
  final double size, drift, speed, wobble, rotationSpeed;
}

class _Balloon {
  _Balloon({
    required this.x,
    required this.y,
    required this.color,
    required this.radius,
    required this.riseSpeed,
    required this.drift,
    required this.wobble,
  });

  final double x, y;
  final Color color;
  final double radius, riseSpeed, drift, wobble;
}

class _FireworkParticle {
  _FireworkParticle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.decay,
  });

  final double angle, speed;
  final Color color;
  final double decay;
}

class _FireworkBurst {
  _FireworkBurst({
    required this.x,
    required this.y,
    required this.startTime,
    required this.particleCount,
    required this.color,
    required Random random,
  }) : particles = List.generate(
            particleCount,
            (_) => _FireworkParticle(
                  angle: random.nextDouble() * 2 * pi,
                  speed: 2 + random.nextDouble() * 4,
                  color: color,
                  decay: 0.92 + random.nextDouble() * 0.06,
                ));

  final double x, y, startTime;
  final int particleCount;
  final Color color;
  final List<_FireworkParticle> particles;
}

class _CelebrationPainter extends CustomPainter {
  _CelebrationPainter({
    required this.progress,
    required this.effect,
    required this.size,
    required this.confettiParticles,
    required this.balloons,
    required this.fireworkBursts,
  });

  final double progress;
  final CelebrationEffect effect;
  final Size size;
  final List<_Particle> confettiParticles;
  final List<_Balloon> balloons;
  final List<_FireworkBurst> fireworkBursts;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    switch (effect) {
      case CelebrationEffect.confetti:
        _paintConfetti(canvas);
        break;
      case CelebrationEffect.balloons:
        _paintBalloons(canvas);
        break;
      case CelebrationEffect.lasers:
        _paintLasers(canvas);
        break;
      case CelebrationEffect.fireworks:
        _paintFireworks(canvas);
        break;
    }
  }

  void _paintConfetti(Canvas canvas) {
    final h = size.height;
    for (final p in confettiParticles) {
      final t = progress * p.speed;
      if (t > 1) continue;
      final fallHeight = h + 60;
      final y = p.y + t * fallHeight;
      final x = p.x + sin(t * pi * 2 * p.wobble) * p.drift;
      if (y < -20 || y > h + 20) continue;
      final rotation = t * p.rotationSpeed * pi;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: p.size,
        height: p.size * 1.6,
      );
      canvas.drawRect(rect, Paint()..color = p.color);
      canvas.restore();
    }
  }

  void _paintBalloons(Canvas canvas) {
    final h = size.height;
    for (final b in balloons) {
      final t = progress * b.riseSpeed;
      final y = b.y - t * (h + 80);
      if (y < -50) continue;
      final x = b.x + sin(t * pi * 2 * b.wobble) * b.drift;
      canvas.save();
      canvas.translate(x, y);
      canvas.drawCircle(Offset.zero, b.radius, Paint()..color = b.color);
      canvas.drawCircle(
        Offset.zero,
        b.radius * 0.85,
        Paint()..color = b.color.withValues(alpha: 0.4),
      );
      canvas.restore();
    }
  }

  void _paintLasers(Canvas canvas) {
    final w = size.width;
    final h = size.height;
    const colors = [
      AppColors.primaryOrange,
      AppColors.onCourtGreen,
      Colors.amber,
      Color(0xFF4A90D9),
    ];
    for (var i = 0; i < 8; i++) {
      final lane = i / 8.0;
      final t = (progress * 1.2 + lane * 0.3) % 1.0;
      final x = -w * 0.3 + t * w * 1.6;
      final color = colors[i % colors.length];
      final alpha = (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0) * 0.6;
      final y = h * (0.2 + lane * 0.6) + sin(progress * pi * 4) * 20;
      final dy = 60.0 + sin(progress * 2) * 20;
      canvas.drawLine(
        Offset(x, y - dy),
        Offset(x, y + dy),
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(x, y - dy),
        Offset(x, y + dy),
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintFireworks(Canvas canvas) {
    final h = size.height;
    for (final burst in fireworkBursts) {
      if (progress < burst.startTime) continue;
      final t = (progress - burst.startTime) / (1 - burst.startTime).clamp(0.2, 1.0);
      if (t > 1) continue;
      for (final p in burst.particles) {
        final dist = p.speed * t * 120 * (1 + t * 0.5);
        final px = burst.x + cos(p.angle) * dist;
        final py = burst.y + sin(p.angle) * dist + t * t * h * 0.15;
        final alpha = (1 - t).clamp(0.0, 1.0) * pow(p.decay, t * 20);
        if (alpha <= 0) continue;
        canvas.drawCircle(
          Offset(px, py),
          2.5,
          Paint()..color = p.color.withValues(alpha: alpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}