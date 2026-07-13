import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/authentication/controllers/authentication_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : AppColors.light,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo ────────────────────────────────────────────
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Image.asset(
                    'assets/images/logo/transparent_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 20),

                // ── App name ─────────────────────────────────────────
                const Text(
                  'MatricMate',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Ethiopian Matric Exam Prep',
                  style: TextStyle(
                    fontSize: 13,
                    color: dark
                        ? AppColors.grey.withValues(alpha: 0.6)
                        : AppColors.darkGrey,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 48),

                // ── Status label ──────────────────────────────────────
                Obx(() {
                  String label = 'Getting things ready…';
                  try {
                    label = AuthenticationController.instance.initStatus.value;
                  } catch (_) {}
                  return Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: dark
                          ? AppColors.grey.withValues(alpha: 0.5)
                          : AppColors.darkGrey.withValues(alpha: 0.6),
                      letterSpacing: 0.2,
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // ── Pulsing dots ──────────────────────────────────────
                const AppPulsingDots(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
