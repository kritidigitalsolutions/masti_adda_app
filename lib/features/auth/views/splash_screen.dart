import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/constants/app_images.dart';
import 'package:masti_adda_app/utils/text_style.dart';
import 'package:masti_adda_app/routes/app_routes.dart';
import '../../../core/services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    // Start animations
    _fadeController.forward();

    // Start navigation timer
    _navigateAfterDelay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _navigateAfterDelay() async {
    // Wait for 2 seconds
    _timer = Timer(const Duration(seconds: 2), () async {
      // Check token from StorageService
      final token = await StorageService.getToken();
      debugPrint('Token: $token');

      if (token == null || token.isEmpty) {
        // No token, go to onboarding
        Get.offAllNamed(AppRoutes.onboarding);
      } else {
        // Token exists, go to home page
        Get.offAllNamed(AppRoutes.home);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated mesh glow background
          const _MeshBackground(),

          // Floating particles (film-grain style dots)
          const _FloatingParticles(),

          // Subtle vignette for depth
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    Colors.transparent,
                    AppColors.backgroundColor.withOpacity(0.55),
                    AppColors.backgroundColor.withOpacity(0.95),
                  ],
                  stops: const [0.3, 0.75, 1.0],
                ),
              ),
            ),
          ),

          // Logo + tagline
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ShimmerLogo(child: Image.asset(AppImages.logo)),
                    const SizedBox(height: 18),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [AppColors.accentColor, AppColors.textColor],
                      ).createShader(bounds),
                      child: Text(
                        'Entertainment Without Limits',
                        style: text18(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Movies • Web Series • Micro Dramas',
                      style: text13(color: AppColors.secondaryTextColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    _AnimatedDivider(),
                    const SizedBox(height: 18),
                    _PulsingTagline(
                      text: 'Watch. Binge. Repeat.',
                      style: text14(
                        color: AppColors.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom loading indicator
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(child: _LoadingDots()),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Animated Mesh Background (two glows orbiting)
// ─────────────────────────────────────────────
class _MeshBackground extends StatefulWidget {
  const _MeshBackground();

  @override
  State<_MeshBackground> createState() => _MeshBackgroundState();
}

class _MeshBackgroundState extends State<_MeshBackground>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
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
        final t = _controller.value * 2 * pi;

        final glow1Alignment = Alignment(0.6 * cos(t), 0.5 * sin(t));
        final glow2Alignment = Alignment(0.6 * cos(t + pi), 0.5 * sin(t + pi));

        return Stack(
          children: [
            Container(color: AppColors.backgroundColor),
            Align(
              alignment: glow1Alignment,
              child: _GlowBlob(
                color: AppColors.accentColor.withOpacity(0.35),
                size: 280,
              ),
            ),
            Align(
              alignment: glow2Alignment,
              child: _GlowBlob(
                color: AppColors.primaryColor.withOpacity(0.30),
                size: 320,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0.0)]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Floating Particles
// ─────────────────────────────────────────────
class _FloatingParticles extends StatefulWidget {
  const _FloatingParticles();

  @override
  State<_FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<_FloatingParticles>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = List.generate(
    24,
    (i) => _Particle.random(Random(i)),
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
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
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            progress: _controller.value,
            color: AppColors.textColor,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  final double dx;
  final double startY;
  final double speed;
  final double radius;
  final double opacity;

  _Particle({
    required this.dx,
    required this.startY,
    required this.speed,
    required this.radius,
    required this.opacity,
  });

  factory _Particle.random(Random r) {
    return _Particle(
      dx: r.nextDouble(),
      startY: r.nextDouble(),
      speed: 0.3 + r.nextDouble() * 0.7,
      radius: 1.0 + r.nextDouble() * 2.0,
      opacity: 0.08 + r.nextDouble() * 0.18,
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.startY - progress * p.speed) % 1.0;
      final offset = Offset(p.dx * size.width, y * size.height);
      final paint = Paint()..color = color.withOpacity(p.opacity);
      canvas.drawCircle(offset, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

// ─────────────────────────────────────────────
// Shimmer Logo (subtle light sweep + breathing)
// ─────────────────────────────────────────────
class _ShimmerLogo extends StatefulWidget {
  final Widget child;
  const _ShimmerLogo({required this.child});

  @override
  State<_ShimmerLogo> createState() => _ShimmerLogoState();
}

class _ShimmerLogoState extends State<_ShimmerLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
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
        final scale = 0.97 + (_controller.value * 0.06);
        return Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentColor.withOpacity(
                    0.25 + (_controller.value * 0.2),
                  ),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────
// Animated divider line
// ─────────────────────────────────────────────
class _AnimatedDivider extends StatefulWidget {
  @override
  State<_AnimatedDivider> createState() => _AnimatedDividerState();
}

class _AnimatedDividerState extends State<_AnimatedDivider>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _widthAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _widthAnim = Tween<double>(
      begin: 0,
      end: 64,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnim,
      builder: (context, child) {
        return Container(
          height: 2,
          width: _widthAnim.value,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accentColor.withOpacity(0),
                AppColors.accentColor,
                AppColors.accentColor.withOpacity(0),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Pulsing tagline text
// ─────────────────────────────────────────────
class _PulsingTagline extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _PulsingTagline({required this.text, required this.style});

  @override
  State<_PulsingTagline> createState() => _PulsingTaglineState();
}

class _PulsingTaglineState extends State<_PulsingTagline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
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
        final opacity = 0.6 + (_controller.value * 0.4);
        return Opacity(opacity: opacity, child: child);
      },
      child: Text(widget.text, style: widget.style),
    );
  }
}

// ─────────────────────────────────────────────
// Bottom loading dots
// ─────────────────────────────────────────────
class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final t = (_controller.value - delay) % 1.0;
            final scale = t < 0.5
                ? 1.0 + (t * 2 * 0.6)
                : 1.0 + ((1 - t) * 2 * 0.6);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale.clamp(1.0, 1.6),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentColor,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
