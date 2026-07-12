import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/bindings/general_binding.dart';
import 'package:matricmate/features/authentication/controllers/authentication_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/routes/routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/themes/app_theme.dart';
import 'package:matricmate/utils/themes/theme_controller.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GetMaterialApp(
        initialBinding: GeneralBinding(),
        debugShowCheckedModeBanner: false,
        themeMode: ThemeController.instance.themeMode.value,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        initialRoute: Routes.loading,
        getPages: AppRoutes.pages,
        navigatorObservers: [appRouteObserver],
      ),
    );
  }
}

// ── Splash / loading screen ───────────────────────────────────────────────────

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
                _PulsingDots(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pulsing dots indicator ────────────────────────────────────────────────────

class _PulsingDots extends StatefulWidget {
  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        // Each dot is offset by 200ms
        final delay = i * 0.2;
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = ((_ctrl.value - delay) % 1.0 + 1.0) % 1.0;
            // smooth bump: up between 0→0.4, down between 0.4→0.8
            final opacity = t < 0.4
                ? (t / 0.4)
                : t < 0.8
                    ? 1.0 - ((t - 0.4) / 0.4)
                    : 0.0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary
                    .withValues(alpha: 0.3 + (opacity * 0.7)),
              ),
            );
          },
        );
      }),
    );
  }
}
