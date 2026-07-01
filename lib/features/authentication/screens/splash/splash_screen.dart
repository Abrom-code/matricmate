import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/authentication/controllers/authentication_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────
  late final AnimationController _fadeScaleCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _loaderCtrl;
  late final AnimationController _particleCtrl;

  // ── Animations ───────────────────────────────────────────────────
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _floatAnim;
  late final Animation<double> _loaderAnim;

  // ── Particles ────────────────────────────────────────────────────
  late final List<_Particle> _particles;

  // ── Brand colours (teal palette to match the app) ────────────────
  static const _bgDark = Color(0xFF00302B);
  static const _bgMid = Color(0xFF004D45);
  static const _accent = AppColors.primary; // teal
  static const _gold = Color(0xFFFFB649);
  static const _goldDim = Color(0xFFFFB954);
  static const _muted = Color(0xFF87BEB6);

  @override
  void initState() {
    super.initState();

    // 1. Fade + scale-in (1.2 s)
    _fadeScaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeScaleCtrl,
      curve: Curves.easeOutCubic,
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _fadeScaleCtrl, curve: Curves.easeOutCubic),
    );

    // 2. Float up/down (6 s loop)
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    // 3. Shimmer (3 s loop)
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // 4. Loader bar (3 s fill)
    _loaderCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _loaderAnim = CurvedAnimation(
      parent: _loaderCtrl,
      curve: Curves.easeOut,
    );

    // 5. Particle tick (continuous)
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60 fps tick
    )..repeat();

    _particles = List.generate(50, (_) => _Particle.random());

    // Start logo fade-in immediately
    _fadeScaleCtrl.forward();

    // Start loader bar slightly after logo appears
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _loaderCtrl.forward();
    });

    // Run minimum display time and auth check in parallel.
    // Navigation happens only when BOTH complete — animation never
    // cuts short, and a fast auth check doesn't make the user wait extra.
    Future.wait([
      Future.delayed(const Duration(milliseconds: 3200)),
      AuthenticationController.instance.prepareRedirect(),
    ]).then((_) {
      if (!mounted) return;
      FlutterNativeSplash.remove();
      AuthenticationController.instance.screenRedirect();
    });
  }

  @override
  void dispose() {
    _fadeScaleCtrl.dispose();
    _floatCtrl.dispose();
    _shimmerCtrl.dispose();
    _loaderCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          // ── Radial gradient background ──────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [Color(0x66004D45), _bgDark, _bgDark],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // ── Floating particles ──────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) {
                for (final p in _particles) {
                  p.update(size);
                }
                return CustomPaint(
                  painter: _ParticlePainter(_particles),
                );
              },
            ),
          ),

          // ── Central content ─────────────────────────────────────
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo badge with float
                    AnimatedBuilder(
                      animation: _floatAnim,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: child,
                      ),
                      child: _LogoBadge(),
                    ),

                    const SizedBox(height: 40),

                    // App name with shimmer
                    AnimatedBuilder(
                      animation: _shimmerCtrl,
                      builder: (_, __) => _ShimmerText(
                        text: 'MatricMate',
                        progress: _shimmerCtrl.value,
                        muted: _muted,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tagline
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3.0,
                          color: _muted,
                        ),
                        children: [
                          const TextSpan(text: 'ETHIOPIAN '),
                          TextSpan(
                            text: 'MATRIC',
                            style: TextStyle(color: _goldDim),
                          ),
                          const TextSpan(text: ' EXAM PREP'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Loader bar ──────────────────────────────────────────
          Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 192,
                height: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: AnimatedBuilder(
                    animation: _loaderAnim,
                    builder: (_, __) => LinearProgressIndicator(
                      value: _loaderAnim.value,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation(_gold),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Footer ──────────────────────────────────────────────
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'MATRICMATE · ETHIOPIA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.school_outlined,
                  size: 11,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo badge ───────────────────────────────────────────────────────────────

class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.45),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Image.asset(
        'assets/images/logo/transparent_logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

// ── Shimmer text ─────────────────────────────────────────────────────────────

class _ShimmerText extends StatelessWidget {
  const _ShimmerText({
    required this.text,
    required this.progress,
    required this.muted,
  });

  final String text;
  final double progress;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final dx = -1.0 + progress * 3.0; // sweeps -1 → +2
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment(dx - 1, 0),
        end: Alignment(dx + 1, 0),
        colors: [Colors.white, muted, Colors.white],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bounds),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: Colors.white,
          height: 1.2,
        ),
      ),
    );
  }
}

// ── Particle system ──────────────────────────────────────────────────────────

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
  });

  factory _Particle.random() {
    final rng = math.Random();
    return _Particle(
      x: rng.nextDouble() * 400,
      y: rng.nextDouble() * 900,
      size: rng.nextDouble() * 1.5 + 0.5,
      speedX: rng.nextDouble() * 0.5 - 0.25,
      speedY: rng.nextDouble() * 0.5 - 0.25,
      opacity: rng.nextDouble() * 0.5,
    );
  }

  double x, y, size, speedX, speedY, opacity;

  void update(Size bounds) {
    x += speedX;
    y += speedY;
    if (x > bounds.width) x = 0;
    if (x < 0) x = bounds.width;
    if (y > bounds.height) y = 0;
    if (y < 0) y = bounds.height;
  }
}

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter(this.particles);
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.size,
        Paint()..color = Colors.white.withValues(alpha: p.opacity * 0.2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}
