import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/features/auth/controllers/register_controller.dart';
import 'package:masti_adda_app/shared/widgets/custom_button.dart';
import 'package:masti_adda_app/utils/text_style.dart';
import 'package:google_fonts/google_fonts.dart';

class AllSetScreen extends StatefulWidget {
  const AllSetScreen({super.key});

  @override
  State<AllSetScreen> createState() => _AllSetScreenState();
}

class _AllSetScreenState extends State<AllSetScreen>
    with SingleTickerProviderStateMixin {
  final RegistrationController controller =
      Get.find<RegistrationController>(); // was Get.put(...)

  late final AnimationController _animController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0, 1, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.2, 1, curve: Curves.easeOutCubic),
          ),
        );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060608),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background: faint movie grid collage ──
          _MovieGridBackground(),

          // ── Dark gradient overlay ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xE6000000),
                  Color(0xF2000000),
                  Color(0xFF000000),
                  Color(0xFF000000),
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),

          // ── Radial glow behind badge ──
          Align(
            alignment: const Alignment(0, -0.35),
            child: FadeTransition(
              opacity: _fade,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentColor.withOpacity(0.35),
                      AppColors.accentColor.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Success badge
                  ScaleTransition(
                    scale: _scale,
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.accentColor,
                            AppColors.accentColor.withOpacity(0.6),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentColor.withOpacity(0.45),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: Column(
                        children: [
                          // All Set! text
                          Text(
                            'All Set!',
                            style: GoogleFonts.poppins(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textColor,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          // Let's Entertain You 🎉
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Let's Entertain You ",
                                style: GoogleFonts.poppins(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentColor,
                                  height: 1.3,
                                ),
                              ),
                              const Text('🎉', style: TextStyle(fontSize: 19)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Subtitle
                          Text(
                            'Unlimited movies, web series, and addictive\nmicro dramas are waiting for you',
                            style: text14(
                              color: AppColors.secondaryTextColor,
                            ).copyWith(height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Start Watching button
                  FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          title: "Start Watching",
                          onTap: controller.startWatching,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Faint movie grid collage background ────────────────────
class _MovieGridBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<Color> colors = [
      const Color(0xFF1A0A2E),
      const Color(0xFF2A0A10),
      const Color(0xFF0A1A2E),
      const Color(0xFF1A1A0A),
      const Color(0xFF0A0A2A),
      const Color(0xFF1E0A0A),
      const Color(0xFF0A1E1A),
      const Color(0xFF1A0E0A),
      const Color(0xFF0E0A1E),
      const Color(0xFF1E1A0A),
      const Color(0xFF0A1A0E),
      const Color(0xFF2A1A0A),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.62,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 36,
      itemBuilder: (_, i) {
        return Container(
          color: colors[i % colors.length],
          child: Center(
            child: Icon(
              i % 3 == 0
                  ? Icons.movie_rounded
                  : i % 3 == 1
                  ? Icons.live_tv_rounded
                  : Icons.theaters_rounded,
              color: Colors.white.withOpacity(0.04),
              size: 36,
            ),
          ),
        );
      },
    );
  }
}
