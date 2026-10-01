import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/utils/constants/colors.dart';

/// A sleek, reactive refresh button for appbars that spins smoothly during refresh operations.
class ReactiveRefreshButton extends StatefulWidget {
  const ReactiveRefreshButton({
    super.key,
    required this.isRefreshing,
    required this.onRefresh,
    this.tooltip = 'Refresh',
    this.tooltipRefreshing = 'Refreshing...',
    this.size = 34,
    this.iconSize = 17,
    this.icon = Iconsax.refresh_copy,
    this.color = AppColors.white,
    this.backgroundColor,
    this.onSuccessMessage,
  });

  /// Whether a refresh is currently running (e.g. from an RxBool observable).
  final bool isRefreshing;

  /// Async callback invoked when the user taps the refresh button.
  final Future<void> Function() onRefresh;

  /// Tooltip text when idle.
  final String tooltip;

  /// Tooltip text while refreshing.
  final String tooltipRefreshing;

  /// Diameter of the circular button container.
  final double size;

  /// Size of the icon.
  final double iconSize;

  /// The icon data to display and spin.
  final IconData icon;

  /// Icon color.
  final Color color;

  /// Container background color. If null, uses a translucent white pill.
  final Color? backgroundColor;

  /// Optional feedback message displayed in a SnackBar on successful completion.
  final String? onSuccessMessage;

  @override
  State<ReactiveRefreshButton> createState() => _ReactiveRefreshButtonState();
}

class _ReactiveRefreshButtonState extends State<ReactiveRefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _isLocalSpinning = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    if (widget.isRefreshing) {
      _ctrl.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ReactiveRefreshButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRefreshing && !oldWidget.isRefreshing) {
      if (!_ctrl.isAnimating) _ctrl.repeat();
    } else if (!widget.isRefreshing && oldWidget.isRefreshing) {
      if (!_isLocalSpinning) {
        _ctrl.stop();
        _ctrl.reset();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (widget.isRefreshing || _isLocalSpinning) return;

    HapticFeedback.lightImpact();
    setState(() => _isLocalSpinning = true);
    if (!_ctrl.isAnimating) _ctrl.repeat();

    try {
      await widget.onRefresh();
      if (mounted &&
          widget.onSuccessMessage != null &&
          widget.onSuccessMessage!.isNotEmpty) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger != null) {
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.onSuccessMessage!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF0D9488),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          );
        }
      }
    } catch (_) {
      // Handled by controller/caller
    } finally {
      if (mounted) {
        setState(() => _isLocalSpinning = false);
        if (!widget.isRefreshing) {
          _ctrl.stop();
          _ctrl.reset();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spinning = widget.isRefreshing || _isLocalSpinning;
    final activeTooltip = spinning ? widget.tooltipRefreshing : widget.tooltip;

    return IconButton(
      tooltip: activeTooltip,
      onPressed: spinning ? null : _handlePress,
      icon: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.backgroundColor ??
              AppColors.white.withValues(alpha: spinning ? 0.28 : 0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) => Transform.rotate(
              angle: _ctrl.value * 2 * math.pi,
              child: child,
            ),
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}
