import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matricmate/utils/constants/colors.dart';

/// A modern gradient app bar that replaces the flat teal [Appbar] for the
/// five main navigation screens.
///
/// Renders a teal gradient [Container] with rounded bottom corners instead of
/// the standard [AppBar] widget so that height and layout are fully
/// customisable without fighting AppBar's internal constraints.
class ModernAppbar extends StatelessWidget implements PreferredSizeWidget {
  const ModernAppbar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBackArrow = false,
  });

  final String title;

  /// Optional subtitle displayed below the title in smaller white text.
  final String? subtitle;

  /// Optional action widgets shown on the right side of the header.
  final List<Widget>? actions;

  /// When true, a back-arrow icon button is prepended on the left.
  final bool showBackArrow;

  // ── preferred height ──────────────────────────────────────────────────────
  @override
  Size get preferredSize => const Size.fromHeight(90);

  @override
  Widget build(BuildContext context) {
    // Keep status-bar icons white while this bar is visible.
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Container(
      height: preferredSize.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF009688), Color(0xFF00BFA5)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── leading ────────────────────────────────────────────────
              if (showBackArrow)
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.white,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              else
                const SizedBox(width: 16),

              // ── title + subtitle ───────────────────────────────────────
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── actions ────────────────────────────────────────────────
              if (actions != null)
                ...actions!
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// A variant of [ModernAppbar] whose subtitle is built lazily via a [builder]
/// callback.  Use this when the subtitle text is reactive (e.g. wrapped in
/// [Obx]) so that only the subtitle rebuilds on state changes.
class ModernAppbarWithBuilder extends StatelessWidget
    implements PreferredSizeWidget {
  const ModernAppbarWithBuilder({
    super.key,
    required this.title,
    this.subtitleBuilder,
    this.actions,
    this.showBackArrow = false,
  });

  final String title;
  final WidgetBuilder? subtitleBuilder;
  final List<Widget>? actions;
  final bool showBackArrow;

  @override
  Size get preferredSize => const Size.fromHeight(90);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Container(
      height: preferredSize.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF009688), Color(0xFF00BFA5)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── leading ────────────────────────────────────────────────
              if (showBackArrow)
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.white,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              else
                const SizedBox(width: 16),

              // ── title + reactive subtitle ──────────────────────────────
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    if (subtitleBuilder != null) ...[
                      const SizedBox(height: 2),
                      Builder(builder: subtitleBuilder!),
                    ],
                  ],
                ),
              ),

              // ── actions ────────────────────────────────────────────────
              if (actions != null)
                ...actions!
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
