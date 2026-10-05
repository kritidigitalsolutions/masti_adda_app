import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/routes/app_routes.dart';
import 'package:masti_adda_app/utils/text_style.dart';

class PremiumWelcomeScreen extends StatelessWidget {
  const PremiumWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 30),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentColor.withOpacity(0.16),
                  border: Border.all(color: AppColors.accentColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentColor.withOpacity(0.28),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.primaryColor,
                  size: 72,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Welcome to\nPremium',
                textAlign: TextAlign.center,
                style: text30(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                'Unlimited entertainment has been unlocked.',
                textAlign: TextAlign.center,
                style: text14(color: AppColors.secondaryTextColor),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: const [
                  _FeaturePill(icon: Icons.block_outlined, label: 'Ad-Free'),
                  _FeaturePill(icon: Icons.high_quality_outlined, label: 'HD Quality'),
                  _FeaturePill(icon: Icons.download_outlined, label: 'Downloads'),
                  _FeaturePill(icon: Icons.devices_rounded, label: '4 Devices'),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Get.offAllNamed(AppRoutes.home),
                child: Container(
                  height: 52,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Start Watching',
                    style: text16(
                      color: AppColors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 15),
          const SizedBox(width: 6),
          Text(label, style: text11(color: AppColors.secondaryTextColor)),
        ],
      ),
    );
  }
}

// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:masti_adda_app/constants/app_colors.dart';
// import 'package:masti_adda_app/constants/app_text_styles.dart';

// class PremiumWelcomeScreen extends StatefulWidget {
//   const PremiumWelcomeScreen({super.key});

//   @override
//   State<PremiumWelcomeScreen> createState() => _PremiumWelcomeScreenState();
// }

// class _PremiumWelcomeScreenState extends State<PremiumWelcomeScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animController;
//   late Animation<double> _scaleAnim;
//   late Animation<double> _glowAnim;

//   @override
//   void initState() {
//     super.initState();
//     _animController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat(reverse: true);

//     _scaleAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
//       CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
//     );
//     _glowAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
//       CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
//     );
//   }

//   @override
//   void dispose() {
//     _animController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundColor,
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   _buildCrownSection(),
//                   const SizedBox(height: 32),
//                   _buildWelcomeText(),
//                   const SizedBox(height: 24),
//                   _buildFeaturePills(),
//                 ],
//               ),
//             ),
//             _buildStartButton(),
//             const SizedBox(height: 30),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCrownSection() {
//     return SizedBox(
//       width: 260,
//       height: 260,
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           // Sparkle dots scattered around
//           ..._buildSparkles(),
//           // Outer glow ring
//           AnimatedBuilder(
//             animation: _glowAnim,
//             builder: (_, __) => Container(
//               width: 160,
//               height: 160,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 boxShadow: [
//                   BoxShadow(
//                     color: AppColors.accentColor.withOpacity(_glowAnim.value * 0.5),
//                     blurRadius: 40,
//                     spreadRadius: 10,
//                   ),
//                 ],
//                 gradient: RadialGradient(
//                   colors: [
//                     AppColors.accentColor.withOpacity(0.15),
//                     Colors.transparent,
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           // Pink circle border
//           Container(
//             width: 140,
//             height: 140,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(
//                 color: AppColors.accentColor,
//                 width: 3,
//               ),
//               color: const Color(0xFF2A1020),
//             ),
//           ),
//           // Crown emoji / icon
//           AnimatedBuilder(
//             animation: _scaleAnim,
//             builder: (_, __) => Transform.scale(
//               scale: _scaleAnim.value,
//               child: const Text('👑', style: TextStyle(fontSize: 64)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   List<Widget> _buildSparkles() {
//     // positions: angle in degrees, distance, color, size
//     final sparkles = [
//       {'angle': 30.0, 'dist': 110.0, 'color': AppColors.primaryColor, 'size': 10.0},
//       {'angle': 60.0, 'dist': 100.0, 'color': AppColors.accentColor, 'size': 7.0},
//       {'angle': 120.0, 'dist': 115.0, 'color': const Color(0xFF00C8FF), 'size': 8.0},
//       {'angle': 150.0, 'dist': 105.0, 'color': AppColors.primaryColor, 'size': 6.0},
//       {'angle': 200.0, 'dist': 112.0, 'color': AppColors.accentColor, 'size': 9.0},
//       {'angle': 240.0, 'dist': 100.0, 'color': const Color(0xFF00C8FF), 'size': 7.0},
//       {'angle': 290.0, 'dist': 108.0, 'color': AppColors.primaryColor, 'size': 8.0},
//       {'angle': 330.0, 'dist': 100.0, 'color': AppColors.accentColor, 'size': 6.0},
//     ];

//     return sparkles.map((s) {
//       final angle = (s['angle'] as double) * math.pi / 180;
//       final dist = s['dist'] as double;
//       final color = s['color'] as Color;
//       final size = s['size'] as double;
//       return Positioned(
//         left: 130 + dist * math.cos(angle) - size / 2,
//         top: 130 + dist * math.sin(angle) - size / 2,
//         child: AnimatedBuilder(
//           animation: _glowAnim,
//           builder: (_, __) => Opacity(
//             opacity: 0.5 + _glowAnim.value * 0.5,
//             child: _SparkleShape(color: color, size: size),
//           ),
//         ),
//       );
//     }).toList();
//   }

//   Widget _buildWelcomeText() {
//     return Column(
//       children: [
//         ShaderMask(
//           shaderCallback: (bounds) => const LinearGradient(
//             colors: [AppColors.primaryColor, AppColors.accentColor],
//           ).createShader(bounds),
//           child: Text(
//             'Welcome to\nPremium',
//             textAlign: TextAlign.center,
//             style: appTextStyle(
//               fontSize: 30,
//               fontWeight: FontWeight.bold,
//               color: AppColors.white,
//               height: 1.2,
//             ),
//           ),
//         ),
//         const SizedBox(height: 10),
//         Text(
//           'Unlimited entertainment\nhas been unlocked.',
//           textAlign: TextAlign.center,
//           style: text14(color: AppColors.secondaryTextColor),
//         ),
//       ],
//     );
//   }

//   Widget _buildFeaturePills() {
//     final features = [
//       {'icon': Icons.block_outlined, 'label': 'Ad-Free'},
//       {'icon': Icons.high_quality_outlined, 'label': 'HD Quality'},
//       {'icon': Icons.download_outlined, 'label': 'Downloads'},
//       {'icon': Icons.eighteen_up_rating_outlined, 'label': '18+ Content'},
//     ];

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 24),
//       child: Wrap(
//         spacing: 8,
//         runSpacing: 8,
//         alignment: WrapAlignment.center,
//         children: features.map((f) {
//           return Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             decoration: BoxDecoration(
//               color: AppColors.surfaceColor,
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(f['icon'] as IconData, color: AppColors.primaryColor, size: 14),
//                 const SizedBox(width: 5),
//                 Text(f['label'] as String, style: text11(color: AppColors.secondaryTextColor)),
//               ],
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   Widget _buildStartButton() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: GestureDetector(
//         onTap: () => Get.offAllNamed('/home'),
//         child: Container(
//           height: 52,
//           width: double.infinity,
//           decoration: BoxDecoration(
//             color: AppColors.primaryColor,
//             borderRadius: BorderRadius.circular(14),
//           ),
//           child: Center(
//             child: Text(
//               'Start Watching',
//               style: text16(color: AppColors.black, fontWeight: FontWeight.bold),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// Custom 4-point sparkle star shape
// class _SparkleShape extends StatelessWidget {
//   final Color color;
//   final double size;
//   const _SparkleShape({required this.color, required this.size});

//   @override
//   Widget build(BuildContext context) {
//     return CustomPaint(
//       size: Size(size, size),
//       painter: _StarPainter(color: color),
//     );
//   }
// }

// class _StarPainter extends CustomPainter {
//   final Color color;
//   _StarPainter({required this.color});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..color = color;
//     final cx = size.width / 2;
//     final cy = size.height / 2;
//     final r = size.width / 2;

//     final path = Path();
//     for (int i = 0; i < 4; i++) {
//       final angle = (i * math.pi / 2) - math.pi / 4;
//       final x = cx + r * math.cos(angle);
//       final y = cy + r * math.sin(angle);
//       if (i == 0) {
//         path.moveTo(x, y);
//       } else {
//         // Curve toward center for star shape
//         path.quadraticBezierTo(cx, cy, x, y);
//       }
//     }
//     path.close();
//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(_StarPainter old) => old.color != color;
// }
