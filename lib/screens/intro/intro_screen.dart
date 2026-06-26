import 'dart:math' as math;
import 'package:flutter/material.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF040D1A);
  static const Color _blue = Color(0xFF1565C0);
  static const Color _cyan = Color(0xFF00E5FF);
  static const Color _red = Color(0xFFFF1744);
  static const Color _white = Color(0xFFFFFFFF);

  late final AnimationController _logoCtrl;
  late final AnimationController _ecgCtrl;
  late final AnimationController _particleCtrl;
  late final AnimationController _taglineCtrl;
  late final AnimationController _finalCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _ecgProgress;
  late final Animation<double> _particleOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _taglineSlide;
  late final Animation<double> _finalFade;
  late final Animation<double> _heartPulse;

  final List<_Cell> _cells = [];
  final math.Random _rng = math.Random(42);

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < 28; i++) {
      _cells.add(
        _Cell(
          x: _rng.nextDouble(),
          y: _rng.nextDouble(),
          r: 4 + _rng.nextDouble() * 10,
          speed: 0.15 + _rng.nextDouble() * 0.4,
          phase: _rng.nextDouble() * math.pi * 2,
          isRed: i < 18,
        ),
      );
    }

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.5)),
    );

    _ecgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _ecgProgress = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ecgCtrl, curve: Curves.easeInOut));
    _heartPulse = Tween(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(
        parent: _ecgCtrl,
        curve: const Interval(0.45, 0.65, curve: Curves.easeInOut),
      ),
    );

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _taglineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _taglineOpacity = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOut));
    _taglineSlide = Tween(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOut));
    _particleOpacity = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOut));

    _finalCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _finalFade = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _finalCtrl, curve: Curves.easeIn));

    _startSequence();
  }

  Future<void> _startSequence() async {
    await _logoCtrl.forward();
    await _ecgCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _ecgCtrl.reset();
    await _ecgCtrl.forward();
    await _taglineCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1600));
    await _finalCtrl.forward();

    if (mounted) {
      // 🔥 This routes to onboarding when the animation finishes!
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _ecgCtrl.dispose();
    _particleCtrl.dispose();
    _taglineCtrl.dispose();
    _finalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _logoCtrl,
          _ecgCtrl,
          _particleCtrl,
          _taglineCtrl,
          _finalCtrl,
        ]),
        builder: (_, __) {
          return Stack(
            children: [
              CustomPaint(
                size: size,
                painter: _GridPainter(opacity: _logoOpacity.value * 0.18),
              ),
              Opacity(
                opacity: _particleOpacity.value,
                child: CustomPaint(
                  size: size,
                  painter: _CellPainter(cells: _cells, t: _particleCtrl.value),
                ),
              ),
              if (_ecgCtrl.value > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  top: size.height * 0.38,
                  child: CustomPaint(
                    size: Size(size.width, 100),
                    painter: _EcgPainter(
                      progress: _ecgProgress.value,
                      color: _cyan,
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _logoScale,
                      child: ScaleTransition(
                        scale: _heartPulse,
                        child: Opacity(
                          opacity: _logoOpacity.value,
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _blue,
                              boxShadow: [
                                BoxShadow(
                                  color: _cyan.withValues(alpha: 
                                    0.35 * _logoOpacity.value,
                                  ),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                                BoxShadow(
                                  color: _blue.withValues(alpha: 
                                    0.5 * _logoOpacity.value,
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.health_and_safety_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - _logoOpacity.value)),
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [_white, _cyan],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Text(
                            'Lifely',
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Opacity(
                      opacity: _taglineOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _taglineSlide.value),
                        child: Column(
                          children: [
                            Text(
                              'Your Blood. Your Health. Your Future.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.65),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: _cyan.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                                color: _cyan.withValues(alpha: 0.08),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _red,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _red.withValues(alpha: 0.8),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'AI · Blood Reports · Disease Detection',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _cyan.withValues(alpha: 0.9),
                                      letterSpacing: 0.8,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 60,
                left: 40,
                right: 40,
                child: Opacity(
                  opacity: _taglineOpacity.value,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: null,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _cyan.withValues(alpha: 0.7),
                          ),
                          minHeight: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Initializing AI Health Engine…',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.4),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_finalCtrl.value > 0)
                Opacity(
                  opacity: _finalFade.value,
                  child: Container(color: Colors.white),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Cell {
  final double x, y, r, speed, phase;
  final bool isRed;
  _Cell({
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
    required this.phase,
    required this.isRed,
  });
}

class _GridPainter extends CustomPainter {
  final double opacity;
  _GridPainter({required this.opacity});
  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final paint = Paint()
      ..color = const Color(0xFF1565C0).withValues(alpha: opacity)
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.opacity != opacity;
}

class _CellPainter extends CustomPainter {
  final List<_Cell> cells;
  final double t;
  _CellPainter({required this.cells, required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    for (final cell in cells) {
      final dy = math.sin(t * math.pi * 2 * cell.speed + cell.phase) * 18;
      final dx = math.cos(t * math.pi * 2 * cell.speed * 0.7 + cell.phase) * 10;
      final cx = cell.x * size.width + dx;
      final cy = cell.y * size.height + dy;

      if (cell.isRed) {
        final fill = Paint()
          ..color = const Color(0xFFFF1744).withValues(alpha: 0.18)
          ..style = PaintingStyle.fill;
        final stroke = Paint()
          ..color = const Color(0xFFFF1744).withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: cell.r * 2.2,
            height: cell.r * 1.4,
          ),
          fill,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: cell.r * 2.2,
            height: cell.r * 1.4,
          ),
          stroke,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: cell.r * 0.9,
            height: cell.r * 0.5,
          ),
          Paint()
            ..color = const Color(0xFFFF1744).withValues(alpha: 0.1)
            ..style = PaintingStyle.fill,
        );
      } else {
        final wbcPaint = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.10)
          ..style = PaintingStyle.fill;
        final wbcStroke = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawCircle(Offset(cx, cy), cell.r * 1.4, wbcPaint);
        canvas.drawCircle(Offset(cx, cy), cell.r * 1.4, wbcStroke);
        canvas.drawCircle(
          Offset(cx - 3, cy - 2),
          cell.r * 0.28,
          Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.25),
        );
        canvas.drawCircle(
          Offset(cx + 2, cy + 2),
          cell.r * 0.2,
          Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CellPainter old) => old.t != t;
}

class _EcgPainter extends CustomPainter {
  final double progress;
  final Color color;
  _EcgPainter({required this.progress, required this.color});
  static const List<Offset> _waypoints = [
    Offset(0.00, 0.50),
    Offset(0.12, 0.50),
    Offset(0.18, 0.45),
    Offset(0.24, 0.50),
    Offset(0.30, 0.52),
    Offset(0.35, 0.05),
    Offset(0.40, 0.90),
    Offset(0.45, 0.50),
    Offset(0.52, 0.40),
    Offset(0.58, 0.50),
    Offset(0.70, 0.50),
    Offset(0.78, 0.45),
    Offset(0.84, 0.50),
    Offset(0.88, 0.52),
    Offset(0.91, 0.10),
    Offset(0.94, 0.88),
    Offset(0.97, 0.50),
    Offset(1.00, 0.50),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final path = Path();
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final totalPts = _waypoints.length;
    final drawCount = (progress * (totalPts - 1)).clamp(0.0, totalPts - 1.0);
    final fullCount = drawCount.floor();
    final frac = drawCount - fullCount;
    Offset pt(int i) =>
        Offset(_waypoints[i].dx * size.width, _waypoints[i].dy * size.height);
    if (fullCount < 1) return;
    path.moveTo(pt(0).dx, pt(0).dy);
    for (int i = 1; i <= fullCount; i++) {
      path.lineTo(pt(i).dx, pt(i).dy);
    }
    if (frac > 0 && fullCount + 1 < totalPts) {
      final from = pt(fullCount);
      final to = pt(fullCount + 1);
      path.lineTo(
        from.dx + (to.dx - from.dx) * frac,
        from.dy + (to.dy - from.dy) * frac,
      );
    }
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
    if (progress < 1.0) {
      final tip = path.getBounds();
      canvas.drawCircle(
        Offset(tip.right, tip.center.dy),
        5,
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        Offset(tip.right, tip.center.dy),
        3,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_EcgPainter old) => old.progress != old.progress;
}
