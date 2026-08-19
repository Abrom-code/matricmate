import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/utils/constants/colors.dart';

/// Wraps standard [Appbar] with optional subtitle.
class ModernAppbar extends StatelessWidget implements PreferredSizeWidget {
  const ModernAppbar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBackArrow = false,
    this.showNotification = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackArrow;
  final bool showNotification;

  @override
  Size get preferredSize {
    final ctx = Get.context;
    if (ctx != null) return Size.fromHeight(Appbar.toolbarHeight(ctx));
    return const Size.fromHeight(kToolbarHeight);
  }

  @override
  Widget build(BuildContext context) {
    return Appbar(
      showBackArrow: showBackArrow,
      actions: actions,
      showNotification: showNotification,
      title: _TitleColumn(
        title: title,
        subtitle: subtitle != null && subtitle!.isNotEmpty
            ? Text(subtitle!, style: _subtitleStyle)
            : null,
      ),
    );
  }
}

/// ModernAppbar accepting a [WidgetBuilder] for reactive subtitles.
class ModernAppbarWithBuilder extends StatelessWidget
    implements PreferredSizeWidget {
  const ModernAppbarWithBuilder({
    super.key,
    required this.title,
    this.subtitleBuilder,
    this.actions,
    this.showBackArrow = false,
    this.showNotification = false,
  });

  final String title;
  final WidgetBuilder? subtitleBuilder;
  final List<Widget>? actions;
  final bool showBackArrow;
  final bool showNotification;

  @override
  Size get preferredSize {
    final ctx = Get.context;
    if (ctx != null) return Size.fromHeight(Appbar.toolbarHeight(ctx));
    return const Size.fromHeight(kToolbarHeight);
  }

  @override
  Widget build(BuildContext context) {
    return Appbar(
      showBackArrow: showBackArrow,
      actions: actions,
      showNotification: showNotification,
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
        if (subtitle != null) ...[const SizedBox(height: 1), subtitle!],
      ],
    );
  }
}
