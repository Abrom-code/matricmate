import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';

/// A reusable appbar sync button that spins while [isSyncing] is true.
///
/// Usage:
///   SyncIconButton(
///     isSyncing: syncController.refreshing.value,
///     tooltip: 'Sync content',
///     onPressed: () => ctrl.syncAll(),
///   )
class SyncIconButton extends StatefulWidget {
  const SyncIconButton({
    super.key,
    required this.isSyncing,
    required this.onPressed,
    this.tooltip,
    this.tooltipSyncing,
    this.size = 20,
    this.color = AppColors.white,
  });

  /// Whether a sync is currently in progress — drives the spin animation.
  final bool isSyncing;

  /// Called when the button is tapped (ignored while [isSyncing] is true).
  final VoidCallback onPressed;

  /// Tooltip shown when idle.
  final String? tooltip;

  /// Tooltip shown while syncing. Defaults to [tooltip] if omitted.
  final String? tooltipSyncing;

  /// Icon + SizedBox size (equal width & height). Defaults to 20.
  final double size;

  /// Icon color. Defaults to [AppColors.white].
  final Color color;

  @override
  State<SyncIconButton> createState() => _SyncIconButtonState();
}

class _SyncIconButtonState extends State<SyncIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (widget.isSyncing) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(SyncIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSyncing && !oldWidget.isSyncing) {
      _ctrl.repeat();
    } else if (!widget.isSyncing && oldWidget.isSyncing) {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeTooltip = widget.isSyncing
        ? (widget.tooltipSyncing ?? widget.tooltip ?? 'Sync in progress…')
        : (widget.tooltip ?? 'Sync');

    return IconButton(
      tooltip: activeTooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.all(0),
      onPressed: widget.isSyncing ? null : widget.onPressed,
      icon: ClipRect(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) => Transform.rotate(
              angle: _ctrl.value * 2 * math.pi,
              child: child,
            ),
            child: Icon(
              Icons.sync_rounded,
              size: widget.size,
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}
