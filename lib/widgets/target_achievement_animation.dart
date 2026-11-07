import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A rich, 60fps moving animation widget for Target Achievement.
/// Features a floating golden trophy & target bullseye, rotating sparkles,
/// pulsating glow rings, and floating celebration confetti.
class TargetAchievementAnimation extends StatefulWidget {
  final double size;
  final bool showCelebrationGlow;

  const TargetAchievementAnimation({
    super.key,
    this.size = 56,
    this.showCelebrationGlow = true,
  });

  @override
  State<TargetAchievementAnimation> createState() => _TargetAchievementAnimationState();
}

class _TargetAchievementAnimationState extends State<TargetAchievementAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // Floating / Bobbing offset
        final hoverY = math.sin(t * 2 * math.pi) * 4.0;
        // Subtle scale breathing
        final scale = 1.0 + math.sin(t * 2 * math.pi) * 0.04;
        // Sparkle rotation
        final rotation = t * 2 * math.pi;
        // Pulse ring expansion (0.0 to 1.0)
        final pulseProgress = (t * 1.5) % 1.0;
        final pulseAlpha = (1.0 - pulseProgress).clamp(0.0, 1.0) * 0.35;

        return SizedBox(
          width: widget.size + 16,
          height: widget.size + 16,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // 1. Pulsating Aura Wave
              if (widget.showCelebrationGlow)
                Transform.scale(
                  scale: 1.0 + pulseProgress * 0.45,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF16A34A).withValues(alpha: pulseAlpha),
                          const Color(0xFFEAB308).withValues(alpha: pulseAlpha * 0.5),
                          Colors.transparent,
                        ],
                        stops: const [0.4, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),

              // 2. Rotating Starburst / Sparkles around the badge
              Transform.rotate(
                angle: rotation * 0.4,
                child: SizedBox(
                  width: widget.size + 14,
                  height: widget.size + 14,
                  child: CustomPaint(
                    painter: _SparklesPainter(
                      progress: t,
                    ),
                  ),
                ),
              ),

              // 3. Floating Confetti Particles drifting
              SizedBox(
                width: widget.size + 16,
                height: widget.size + 16,
                child: CustomPaint(
                  painter: _ConfettiPainter(
                    progress: t,
                  ),
                ),
              ),

              // 4. Moving Achievement Badge (Bobs up and down smoothly)
              Transform.translate(
                offset: Offset(0, hoverY),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFFFEF08A), // Light gold
                          Color(0xFFF59E0B), // Warm amber gold
                          Color(0xFFD97706), // Rich gold
                        ],
                        center: Alignment(-0.2, -0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD97706).withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white,
                        width: 2.2,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Target rings inside
                        SizedBox(
                          width: widget.size * 0.8,
                          height: widget.size * 0.8,
                          child: CustomPaint(
                            painter: _TargetBullseyePainter(
                              gleamPhase: t,
                            ),
                          ),
                        ),

                        // Center Trophy & Target Icon
                        Icon(
                          Icons.military_tech_rounded,
                          size: widget.size * 0.55,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              color: Color(0xFF78350F),
                              blurRadius: 4,
                              offset: Offset(0, 1.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 5. Target Bullseye Dart Indicator (top right)
              Positioned(
                top: 0 + hoverY * 0.6,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 11,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for the concentric target rings with rotating gleam
class _TargetBullseyePainter extends CustomPainter {
  final double gleamPhase;

  _TargetBullseyePainter({required this.gleamPhase});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer Target Ring (Emerald green)
    final greenPaint = Paint()
      ..color = const Color(0xFF16A34A).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius * 0.88, greenPaint);

    // Inner Target Ring (White)
    final whitePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius * 0.60, whitePaint);

    // Target Bullseye (Red/Gold center)
    final bullseyePaint = Paint()
      ..color = const Color(0xFFDC2626).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.32, bullseyePaint);

    // Shimmer gleam sweep
    final gleamAngle = gleamPhase * 2 * math.pi;
    final gleamPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.45),
          Colors.transparent,
        ],
        stops: const [0.0, 0.15, 0.3],
        transform: GradientRotation(gleamAngle),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, gleamPaint);
  }

  @override
  bool shouldRepaint(_TargetBullseyePainter oldDelegate) =>
      oldDelegate.gleamPhase != gleamPhase;
}

/// Custom painter for rotating sparkling stars
class _SparklesPainter extends CustomPainter {
  final double progress;

  _SparklesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final starAngles = [
      0.0,
      math.pi * 0.45,
      math.pi * 0.85,
      math.pi * 1.35,
      math.pi * 1.75,
    ];

    for (int i = 0; i < starAngles.length; i++) {
      final baseAngle = starAngles[i];
      final currentAngle = baseAngle;
      final sparkleRadius = radius * 0.95;
      final x = center.dx + math.cos(currentAngle) * sparkleRadius;
      final y = center.dy + math.sin(currentAngle) * sparkleRadius;

      // Twinkle scale
      final twinkle = (math.sin((progress * 4 * math.pi) + (i * 1.2)) + 1) / 2;
      final starSize = 2.2 + twinkle * 2.2;

      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFFFDE047),
          const Color(0xFF38BDF8),
          (i % 2).toDouble(),
        )!.withValues(alpha: 0.35 + twinkle * 0.6)
        ..style = PaintingStyle.fill;

      // Draw 4-point star
      _drawStar(canvas, Offset(x, y), starSize, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Custom painter for floating colorful celebration confetti
class _ConfettiPainter extends CustomPainter {
  final double progress;

  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final particles = [
      // {radius, angleOffset, color, speed, size}
      _Particle(radius: 28, angle: 0.2, color: const Color(0xFF10B981), size: 3.5),
      _Particle(radius: 34, angle: 1.1, color: const Color(0xFFF59E0B), size: 3.0),
      _Particle(radius: 30, angle: 2.3, color: const Color(0xFF3B82F6), size: 4.0),
      _Particle(radius: 32, angle: 3.6, color: const Color(0xFFEC4899), size: 3.2),
      _Particle(radius: 36, angle: 4.8, color: const Color(0xFF8B5CF6), size: 3.5),
      _Particle(radius: 29, angle: 5.7, color: const Color(0xFF10B981), size: 3.0),
    ];

    for (final p in particles) {
      // Gentle floating oscillation
      final floatY = math.sin((progress * 2 * math.pi) + p.angle) * 3.5;
      final currentAngle = p.angle + math.sin(progress * 2 * math.pi) * 0.15;
      final x = center.dx + math.cos(currentAngle) * p.radius;
      final y = center.dy + math.sin(currentAngle) * p.radius + floatY;

      final paint = Paint()
        ..color = p.color.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 4 * math.pi + p.angle);
      // Draw small rectangular confetti ribbon
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size * 1.5, height: p.size * 0.8),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Particle {
  final double radius;
  final double angle;
  final Color color;
  final double size;

  const _Particle({
    required this.radius,
    required this.angle,
    required this.color,
    required this.size,
  });
}
