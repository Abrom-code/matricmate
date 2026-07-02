import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/utils/constants/colors.dart';

/// Wraps the standard [Appbar] and adds an optional static [subtitle] line
/// below the title. Shape, colour, and height are identical to [Appbar].
class ModernAppbar extends StatelessWidget implements PreferredSizeWidget {
  const ModernAppbar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBackArrow = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackArrow;

  @override
  Size get preferredSize => const _AppbarSize();

  @override
  Widget build(BuildContext context) {
    return Appbar(
      showBackArrow: showBackArrow,
      actions: actions,
      title: _TitleColumn(
        title: title,
        subtitle: subtitle != null && subtitle!.isNotEmpty
            ? Text(subtitle!, style: _subtitleStyle)
            : null,
      ),
    );
  }
}

/// Same as [ModernAppbar] but accepts a [WidgetBuilder] for the subtitle so
/// reactive widgets (e.g. [Obx]) can be placed there without rebuilding the
/// whole bar.
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
  Size get preferredSize => const _AppbarSize();

  @override
  Widget build(BuildContext context) {
    return Appbar(
      showBackArrow: showBackArrow,
      actions: actions,
      title: _TitleColumn(
        title: title,
        subtitle: subtitleBuilder != null
            ? Builder(builder: subtitleBuilder!)
            : null,
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

const _subtitleStyle = TextStyle(
  color: Colors.white70,
  fontSize: 12,
  fontWeight: FontWeight.w400,
);

/// Title + optional subtitle stacked in a left-aligned column.
class _TitleColumn extends StatelessWidget {
  const _TitleColumn({required this.title, this.subtitle});

  final String title;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 1),
          subtitle!,
        ],
      ],
    );
  }
}

/// Delegates preferred height to [Appbar.preferredSize] without
/// instantiating an [Appbar] at const-evaluation time.
class _AppbarSize extends Size {
  const _AppbarSize() : super.fromHeight(56);
}
